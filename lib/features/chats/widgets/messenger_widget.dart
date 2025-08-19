import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/chats/models/message.dart';
import 'package:teamup/features/chats/widgets/message_widget.dart';
import 'package:teamup/widgets/shimmer_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';

class MessengerWidget extends StatefulWidget {
  const MessengerWidget({super.key, required this.chat});
  final Chat chat;

  @override
  State<MessengerWidget> createState() => _MessengerWidgetState();
}

class _MessengerWidgetState extends State<MessengerWidget> {
  final userBloc = GetIt.I<UserBloc>();
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  final chatsRepository = GetIt.I<ChatsRepository>();
  final supabase = GetIt.I<SupabaseClient>();

  List<Message>? messages;
  late RealtimeChannel channel;

  Message? editingMessage;
  Message? replyMessage;
  String tmpMessage = '';

  @override
  void initState() {
    super.initState();
    loadMessages();
    listenMessages();
  }

  Future<void> loadMessages() async {
    messages = await chatsRepository.getMessages(widget.chat.id);
    setState(() {});
    scrollToBottom();
    sortMessages();
  }

  void listenMessages() {
    channel = supabase.channel('new-messages-channel');
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'chat',
      value: widget.chat.id,
    );

    channel.onPostgresChanges(
      table: 'messages',
      filter: filter,
      event: PostgresChangeEvent.insert,
      callback: (payload) {
        if (payload.newRecord['sender'] == supabase.auth.currentUser!.id) return;
        final sender = widget.chat.users
            .where((user) => user.uid == payload.newRecord['sender'])
            .toList()[0];
        payload.newRecord['sender'] = sender.toJSON();
        messages?.add(Message.fromJSON(payload.newRecord));
        setState(() {});
        scrollToBottomAnimated();
        sortMessages();
      },
    );

    channel.onPostgresChanges(
      table: 'messages',
      filter: filter,
      event: PostgresChangeEvent.update,
      callback: (payload) {
        messages = messages?.map((message) {
          if (message.id == payload.newRecord['id']) {
            final sender = widget.chat.users
                .where((user) => user.uid == payload.newRecord['sender'])
                .toList()[0];
            payload.newRecord['sender'] = sender.toJSON();
            return Message.fromJSON(payload.newRecord);
          }
          return message;
        }).toList();
        setState(() {});
      },
    );

    channel.onPostgresChanges(
      table: 'messages',
      filter: filter,
      event: PostgresChangeEvent.delete,
      callback: (payload) {
        messages = messages
            ?.where((message) => message.id != payload.oldRecord['id'])
            .toList();
        setState(() {});
        scrollToBottomAnimated();
        sortMessages();
      },
    );

    channel.subscribe();
  }

  void onSendMessage() {
    if (messageController.text == '') return;
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chat.id,
      user: (userBloc.state as UserStateLoaded).user,
      text: messageController.text,
      repliedMesssageID: replyMessage?.id,
      time: DateTime.now(),
    );
    messages?.add(message);
    setState(() {});
    chatsRepository.sendMessage(message);

    messageController.text = '';
    replyMessage = null;
    scrollToBottomAnimated();
    sortMessages();
  }

  void onEditMessage() {
    if (messageController.text == '') return;
    for (Message message in messages!) {
      if (message.id == editingMessage!.id)
        message.text = messageController.text;
      break;
    }
    chatsRepository.editMessage(editingMessage!.id, messageController.text);
    editingMessage = null;
    messageController.text = tmpMessage;
    setState(() {});
  }

  void onSetEditing(Message message) {
    editingMessage = message;
    tmpMessage = messageController.text;
    messageController.text = message.text;
    setState(() {});
  }

  void onCancelEditing() {
    editingMessage = null;
    messageController.text = tmpMessage;
    setState(() {});
  }

  void onSetReply(Message message) {
    replyMessage = message;
    tmpMessage = messageController.text;
    messageController.text = '';
    setState(() {});
  }

  void onCancelReply() {
    replyMessage = null;
    messageController.text = tmpMessage;
    setState(() {});
  }

  void onDeleteMessage(int id) {
    messages = messages?.where((message) => message.id != id).toList();
    setState(() {});
    scrollToBottomAnimated();
    sortMessages();
    chatsRepository.deleteMessage(id);
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 20)).then((_) => scrollController.jumpTo(scrollController.position.maxScrollExtent));
      return;
    }
    Future.delayed(Duration(milliseconds: 1)).then((val) => scrollToBottom());
  }

  void scrollToBottomAnimated() {
    if (messages!.isNotEmpty) {
      Future.delayed(Duration(milliseconds: 20)).then((val) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent, 
          duration: Duration(milliseconds: 250),
          curve: Curves.ease,
        );
      });
    }
  }

  void sortMessages() {
    // if (messages != null) {
    //   for (int i = 0; i < messages!.length - 1; i++) {
    //     for (int j = 0; j < messages!.length - i - 1; j++) {
    //       if (messages![j].time.millisecondsSinceEpoch > messages![j + 1].time.millisecondsSinceEpoch) {
    //         Message tmp = messages![j];
    //         messages![j] = messages![j + 1];
    //         messages![j + 1] = tmp;
    //       }
    //     }
    //   }
    //   setState(() {});
    // }
  }

  @override
  void dispose() {
    super.dispose();
    supabase.removeChannel(channel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
        if (state is UserStateLoaded) {
          return Column(
            children: [
              Expanded(
                child: messages != null
                ? messages!.isNotEmpty
                  ? ListView.builder(
                      controller: scrollController,
                      itemCount: messages!.length,
                      itemBuilder: (context, i) {
                        return Column(
                          children: [
                            if (i > 0 && (messages![i].time.day != messages![i - 1].time.day ||
                              messages![i].time.month != messages![i - 1].time.month ||
                              messages![i].time.year != messages![i - 1].time.year)
                            )
                            Center(
                              child: Text(
                                '${messages![i].time.day.toString().padLeft(2, '0')}.${messages![i].time.month.toString().padLeft(2, '0')}.${messages![i].time.year}',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                                  messages![i].user.uid == state.user.uid
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                MessageWidget(
                                  message: messages![i],
                                  onEditMessage: onSetEditing,
                                  onDeleteMessage: onDeleteMessage,
                                  messages: messages!,
                                  onReplyMessage: onSetReply,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Напишите первыми!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                : ListView.builder(
                    itemCount: 3 + Random().nextInt(4),
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment: Random().nextInt(2) == 1 ? MainAxisAlignment.start : MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: SihmmerWidget(width: 300, height: 80)
                          )
                        ]
                      );
                    },
                )
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    if (editingMessage != null)
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsGeometry.all(5),
                              child: Row(
                                children: [
                                  Text(
                                    'Редактирование: ',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      editingMessage!.text,
                                      style: theme.textTheme.labelMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onCancelEditing,
                            icon: Icon(Icons.remove, size: 35),
                          ),
                        ],
                      ),
                      if (replyMessage != null)
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsGeometry.all(5),
                              child: Row(
                                children: [
                                  Text(
                                    'В ответ на: ',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      replyMessage!.text,
                                      style: theme.textTheme.labelMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  )
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onCancelReply,
                            icon: Icon(Icons.remove, size: 35),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: TextFormField(
                              keyboardType: TextInputType.multiline,
                              controller: messageController,
                              maxLines: null,
                              decoration: InputDecoration(
                                hint: Text('Сообщение...'),
                                hintStyle: theme.textTheme.labelLarge,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        if (editingMessage != null)
                          IconButton(
                            onPressed: onEditMessage,
                            icon: Icon(Icons.check, size: 35),
                          )
                        else
                          IconButton(
                            onPressed: onSendMessage,
                            icon: Icon(Icons.send, size: 35),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        } 
        return SizedBox.shrink();
      },
    );
  }
}
