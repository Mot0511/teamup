import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/models/message.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';

class MessageWidget extends StatefulWidget {
  MessageWidget({
    super.key, 
    required this.message, 
    required this.messages, 
    this.onDeleteMessage, 
    this.onEditMessage,
    this.onReplyMessage,
  });
  final Message message;
  final List<Message> messages;
  final Function? onDeleteMessage;
  final Function? onEditMessage;
  final Function? onReplyMessage;

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  final userBloc = GetIt.I<UserBloc>();

  Offset? tapPosition;
  double offsetX = 0.0;

  void showContextMenu() async {
    if (tapPosition == null) return;
    final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    final theme = Theme.of(context);

    final List<PopupMenuItem> popupItems = [
      PopupMenuItem(child: Text("Ответить", style: theme.textTheme.labelSmall), value: 'reply'),
    ];
    if (widget.message.user.uid == (userBloc.state as UserStateLoaded).user.uid) {
      popupItems.addAll([
        PopupMenuItem(child: Text("Изменить", style: theme.textTheme.labelSmall), value: 'edit'),
        PopupMenuItem(child: Text("Удалить", style: theme.textTheme.labelSmall), value: 'delete'),
      ]);
    }
    final res = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition!.dx, tapPosition!.dy, 30, 30), 
        Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, 
          overlay.paintBounds.size.height)
      ),
      items: popupItems
    );

    switch (res) {
      case 'reply':
        widget.onReplyMessage!(widget.message);
        break;
      case 'edit':
        widget.onEditMessage!(widget.message);
        break;
      case 'delete':
        widget.onDeleteMessage!(widget.message.id);
        break;
    }

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
        if (state is UserStateLoaded) {
          return GestureDetector(
            onTapDown: (details) => setState(() => tapPosition = details.globalPosition),
            onLongPress: showContextMenu,
            onHorizontalDragUpdate: (details) {
              offsetX += details.delta.dx;

              if (offsetX >= 0) offsetX = 0;
              if (offsetX < -100) offsetX = -100;
              setState(() {});
            },
            onHorizontalDragEnd: (details) {
              if (offsetX < -80) {
                widget.onReplyMessage!(widget.message);
              }
              setState(() => offsetX = 0.0);
            },
            child: SizedBox(
              width: 300,
              child: Transform.translate(
                offset: Offset(offsetX, 0),
                child: Container(
                  margin: EdgeInsets.all(5),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.message.user.uid == state.user.uid ? theme.primaryColor : Colors.cyan[800],
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(widget.message.user.username, style: theme.textTheme.bodyMedium),
                                SizedBox(width: 10),
                                if (widget.message.repliedMesssageID != null)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      widget.messages.where((message) => message.id == widget.message.repliedMesssageID).toList()[0].text, 
                                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  )
                                ),
                              ],
                            ),
                            Text(widget.message.text, style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        '${widget.message.time.hour}:${(widget.message.time.minute.toString().padLeft(2, '0'))}', 
                        style: TextStyle(fontSize: 14, color: Colors.grey)
                      ),
                    ],
                  )
                ),
              )
            )
          );
        }
        return SizedBox.shrink();
      }
    );
  }
}