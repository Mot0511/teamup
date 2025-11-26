import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/bloc/chats_bloc.dart';
import 'package:teamup/features/chats/bloc/chats_events.dart';
import 'package:teamup/features/chats/bloc/chats_states.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/chats/widgets/chat_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/analytics/repositories/analytics_repository.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class ChatsView extends StatefulWidget {
  ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final chatsRepository = GetIt.I<ChatsRepository>();
  

  final userBloc = GetIt.I<UserBloc>();
  final chatsBloc = GetIt.I<ChatsBloc>();

  @override
  void initState() {
    super.initState();
    
    loadChats();
    userBloc.stream.listen((state) async {
      loadChats();
    });
  }

  void loadChats({Completer? completer}) {
    if (userBloc.state is UserStateLoaded && (chatsBloc.state is ChatsStateInitial || completer != null)) {
      chatsBloc.add(LoadChats(uid: (userBloc.state as UserStateLoaded).user.uid, completer: completer));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Личные чаты'),
        actions: [
          if (!Platform.isAndroid)
          IconButton(onPressed: () {
            final completer = Completer();
            loadChats(completer: completer);
          }, icon: Icon(Icons.refresh))
        ],
       ),
      body: RefreshIndicator(
        onRefresh: () {
          final completer = Completer();
          loadChats(completer: completer);
          return completer.future;
        },
        child: BlocBuilder<UserBloc, UserState>(
          bloc: userBloc,
          builder: (context, userState) {
            return BlocBuilder<ChatsBloc, ChatsState>(
              bloc: chatsBloc,
              builder: (context, chatsState) {
                if (userState is UserStateLoaded && chatsState is ChatsStateLoaded) {
                  if (chatsState.chats.isNotEmpty) {
                    return ListView(
                      children: chatsState.chats.map((Chat chat) => ChatWidget(chat: chat)).toList()
                    );
                  } else {
                    return CustomScrollView(
                      shrinkWrap: true,
                      slivers: [
                        SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('У тебя нет личных чатов', style: theme.textTheme.titleMedium),
                        ),
                      ),
                      ],
                    );
                  }
                } else if (userState is UserStateError || chatsState is ChatsStateError) {
                  return Center(child: Text('Произошла ошибка при загрузке чатов', style: theme.textTheme.titleMedium));
                } else {
                  return ListView.builder(
                    itemCount: 3 + Random().nextInt(5),
                    itemBuilder: (context, state) => 
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: SihmmerWidget(),
                      )
                  );
                }
              }
            );
          },
        )
      )
    );
  }
}