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
    if (userBloc.state is UserStateLoaded && chatsBloc.state is ChatsStateInitial) {
      chatsBloc.add(LoadChats(uid: (userBloc.state as UserStateLoaded).user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Личные чаты')),
      body: BlocBuilder<UserBloc, UserState>(
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
                  return Center(child: Text('У тебя нет личных чатов', style: theme.textTheme.titleMedium));
                }
              } else if (userState is UserStateError || chatsState is ChatsStateError) {
                return Center(child: Text('Произошла ошибка при загрузке чатов', style: theme.textTheme.titleMedium));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }
          );
        },
      )
    );
  }
}