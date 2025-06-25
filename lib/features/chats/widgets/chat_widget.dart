import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/models/models.dart';
import 'package:teamup/features/chats/views/chat_view.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';

class ChatWidget extends StatelessWidget {
  ChatWidget({super.key, required this.chat});
  final Chat chat;

  final userBloc = GetIt.I<UserBloc>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(chat.id.toString()), 
      background: Container(color: Colors.red),
      child: BlocBuilder<UserBloc, UserState>(
        bloc: userBloc,
        builder: (context, state) {
          if (state is UserStateLoaded) {
            return ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatView(chat: chat))),
              leading: AvatarWidget(uid: state.user.uid == chat.user1.uid ? chat.user1.uid : chat.user2.uid, size: 50),
              title: Text(state.user.uid == chat.user1.uid ? chat.user1.uid : chat.user2.uid, style: theme.textTheme.labelMedium),
              subtitle: Text('Последнее сообщение', style: theme.textTheme.labelSmall),
            );
          } else {
            return SizedBox.shrink();
          }
        }
      )
    );
  }
}