import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.chat});
  final Chat chat;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {

  bool isVoice = true;
  bool isSound = true;

  final userBloc = GetIt.I<UserBloc>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user1 = widget.chat.user1;
    final user2 = widget.chat.user2;
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
        if (state is UserStateLoaded) {
          final user = user1.uid == state.user.uid ? user2 : user1;
          return Scaffold(
            appBar: AppBar(
              title: ListTile(
                title: Text(user.username, style: theme.textTheme.labelMedium),
                subtitle: Text('В сети', style: theme.textTheme.labelSmall),
              ),
              actions: [
                IconButton(
                  onPressed: () => setState(() => isVoice = !isVoice),
                  icon: Icon(isVoice ? Icons.phone_enabled : Icons.phone_disabled)
                ),
                IconButton(
                  onPressed: () => setState(() => isSound = !isSound),
                    icon: Icon(isSound ? Icons.headset_mic : Icons.headset_off)
                  ),
              ],
            ),
          );
        } else {
          return Scaffold();
        }
      }
    );
  }
}