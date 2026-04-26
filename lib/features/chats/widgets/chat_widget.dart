import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/user/user.dart';

class ChatWidget extends StatefulWidget {
  ChatWidget({super.key, required this.chat});
  final Chat chat;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final userBloc = GetIt.I<UserBloc>();
  final chatsBloc = GetIt.I<ChatsBloc>();
  final supabase = GetIt.I<SupabaseClient>();

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

    final user = (userBloc.state as UserStateLoaded).user;
    late User other;
    if (widget.chat.users.isNotEmpty) {
      other = user.uid == widget.chat.users[0].uid ? widget.chat.users[1] : widget.chat.users[0];
    }
    
    return Dismissible(
      key: Key(widget.chat.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(color: theme.colorScheme.error),
      onDismissed: (direction) => removeChat(),
      child: GestureDetector(
        onTapDown: (details) => setState(() => tapPosition = details.globalPosition),
        onLongPress: () => showContextMenu(context),
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatView(chat: widget.chat))),
          leading: AvatarWidget(uid: other.uid, size: 50),
          title: Text(other.username, style: theme.textTheme.labelMedium),
          subtitle: widget.chat.lastMessage != null 
            ? Text(widget.chat.lastMessage!, style: theme.textTheme.labelSmall)
            : null
        )
      )
    );
  }
}