import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/chats/models/message.dart';
import 'package:teamup/features/chats/widgets/message_widget.dart';
import 'package:teamup/features/chats/widgets/messenger_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/views/views.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';
import 'package:teamup/features/analytics/repositories/analytics_repository.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.chat});
  final Chat chat;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {

  final userBloc = GetIt.I<UserBloc>();
  final userRepository = GetIt.I<UserRepository>();
  final analyticsRepository = GetIt.I<AnalyticsRepository>();
  final supabase = GetIt.I<SupabaseClient>();
  late RealtimeChannel isOnlineChannel;

  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    analyticsRepository.logEvent('open_chat_screen');
    getIsOnline();
  }

  Future<void> getIsOnline() async {
    final user = (userBloc.state as UserStateLoaded).user;
    final user1 = widget.chat.users[0];
    final user2 = widget.chat.users[1];

    isOnline = await userRepository.getIsOnline(user1.uid == user.uid ? user2.uid : user1.uid);
    setState(() {});
    
    isOnlineChannel = supabase.channel('is-online-channel');
    isOnlineChannel.onPostgresChanges(
      table: 'users',
      event: PostgresChangeEvent.update,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'uid',
        value: user1.uid == user.uid ? user2.uid : user1.uid
      ),
      callback: (payload) {
        if (payload.newRecord['uid'] != user.uid) {
          isOnline = payload.newRecord['isOnline'];
          setState(() {});
        }
      }
    );

    isOnlineChannel.subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(isOnlineChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user1 = widget.chat.users[0];
    final user2 = widget.chat.users[1];
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
        if (state is UserStateLoaded) {
          final user = user1.uid == state.user.uid ? user2 : user1;
          return Scaffold(
            appBar: AppBar(
              title: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileView(user: user))),
                leading: AvatarWidget(uid: user.uid, size: 50),
                title: Text(user.username, style: theme.textTheme.labelMedium),
                subtitle: isOnline ? Text('в сети', style: theme.textTheme.labelSmall?.copyWith(color: theme.primaryColor)) : null
              ),
            ),
            body: MessengerWidget(chat: widget.chat)
          );
        } else if (state is UserStateError) {
          return Scaffold(
            body: Center(child: Text('Произошла ошибка при загрузке данных пользователя', style: theme.textTheme.titleMedium)),
          );
        } else {
          return Scaffold();
        }
      }
    );
  }
}