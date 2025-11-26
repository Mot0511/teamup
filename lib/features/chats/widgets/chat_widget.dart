import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/bloc/chats_bloc.dart';
import 'package:teamup/features/chats/bloc/chats_events.dart';
import 'package:teamup/features/chats/models/models.dart';
import 'package:teamup/features/chats/views/chat_view.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';

class ChatWidget extends StatefulWidget {
  ChatWidget({super.key, required this.chat});
  final Chat chat;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final userBloc = GetIt.I<UserBloc>();
  final chatsBloc = GetIt.I<ChatsBloc>();

  Offset? tapPosition;

  void removeChat() {
    chatsBloc.add(RemoveChat(chat: widget.chat));
  }

  void showContextMenu(context) async {
    if (tapPosition == null) return;
    final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    final theme = Theme.of(context);

    final result = await showMenu(  
      color: theme.cardColor,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition!.dx, tapPosition!.dy, 30, 30), 
        Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                overlay.paintBounds.size.height)),
      context: context, 
      items: [
        PopupMenuItem(child: Text('Удалить чат', style: theme.textTheme.labelSmall), value: 'removeChat')
      ]
    );

    if (result == 'removeChat') removeChat();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(widget.chat.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(color: theme.colorScheme.error),
      onDismissed: (direction) => removeChat(),
      child: BlocBuilder<UserBloc, UserState>(
        bloc: userBloc,
        builder: (context, state) {
          if (state is UserStateLoaded) {
            return GestureDetector(
              onTapDown: (details) => setState(() => tapPosition = details.globalPosition),
              onLongPress: () => showContextMenu(context),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatView(chat: widget.chat))),
                leading: AvatarWidget(uid: state.user.uid == widget.chat.users[0].uid ? widget.chat.users[1].uid : widget.chat.users[0].uid, size: 50),
                title: Text(state.user.uid == widget.chat.users[0].uid ? widget.chat.users[1].username : widget.chat.users[0].username, style: theme.textTheme.labelMedium),
              )
            );
          } else {
            return SizedBox.shrink();
          }
        }
      )
    );
  }
}