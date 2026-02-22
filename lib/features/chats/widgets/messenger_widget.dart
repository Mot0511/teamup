import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/widgets/shimmer_widget.dart';
import 'package:teamup/features/user/user.dart';

class MessengerWidget extends StatefulWidget {
  const MessengerWidget({super.key, required this.chat});
  final Chat chat;

  @override
  State<MessengerWidget> createState() => _MessengerWidgetState();
}

class _MessengerWidgetState extends State<MessengerWidget> {
  final supabase = GetIt.I<SupabaseClient>();
  final userBloc = GetIt.I<UserBloc>();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  final messageController = TextEditingController();
  final focusNode = FocusNode();
  final scrollController = ScrollController();

  List<Message>? messages;
  late RealtimeChannel channel;

  Message? editingMessage;
  Message? replyMessage;
  String tmpMessage = '';
  Uint8List? attachmentBytes;

  bool isMember = false;


  @override
  void initState() {
    super.initState();
    checkIsMember();
    loadMessages();
    listenMessages();
  }

  void checkIsMember() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    isMember = widget.chat.users.map((user) => user.uid).toList().contains(uid);
    setState(() {});
  }

  Future<void> loadMessages() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    messages = await chatsRepository.getMessages(uid, widget.chat.id);
    setMessagesReaded(uid);
    setState(() {});
    scrollToBottom();
    sortMessages();
  }

  Future<void> setMessagesReaded(String uid) async {
    if (messages == null) return;
    for (Message message in messages!) {
      if (message.user.uid != uid && !message.isReaded) {
        await chatsRepository.setReaded(uid, message.id, widget.chat.id);
        channel.sendBroadcastMessage(event: 'readed-message', payload: {'messageID': message.id});
      }
    }
  }

  void listenMessages() {
    channel = supabase.channel('chat-${widget.chat.id}');
    
    channel.onBroadcast(
      event: 'new-message',
      callback: (payload) async {
        final uid = supabase.auth.currentUser!.id;
        if (payload['sender'] == uid) return;
        final sender = widget.chat.users
            .where((user) => user.uid == payload['sender'])
            .toList()[0];
        payload['sender'] = sender.toJSON();
        if (payload['attachmentBytes'] != null) {
          payload['attachmentBytes'] = await chatsRepository.getAttachment(payload['attachmentBytes']);
        }
        await chatsRepository.setReaded(uid, payload['id'], widget.chat.id);
        messages?.add(Message.fromJSON(payload, true));
        setState(() {});
        scrollToBottomAnimated();
        sortMessages();
      },
    );

    channel.onBroadcast(
      event: 'edit-message',
      callback: (payload) async {
        if (messages != null) {
          for (int i = messages!.length - 1; i >= 0; i--) {
            final message = messages![i];
            if (message.id == payload['messageID']) {
              message.text = payload['text'];
              break;
            }
          }
          setState(() {});
        }
      },
    );

    channel.onBroadcast(
      event: 'delete-message', 
      callback: (payload) {
        messages = messages
            ?.where((message) => message.id != payload['messageID'])
            .toList();
        setState(() {});
        sortMessages();
      },
    );

    channel.onBroadcast(
      event: 'readed-message',
      callback: (payload) {
        if (messages == null) return;
        for (int i = messages!.length - 1; i >= 0; i--) {
          final Message message = messages![i];
          if (message.id == payload['messageID']) {
            message.isReaded = true;
            setState(() {});
            break;
          }
        }
      },
    );

    channel.subscribe();
  }
  

  void onSendMessage() {
    final text = messageController.text.trim();
    if (text == '' && attachmentBytes == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      chatId: widget.chat.id,
      user: (userBloc.state as UserStateLoaded).user,
      text: text,
      repliedMesssageID: replyMessage?.id,
      attachment: attachmentBytes != null ? MemoryImage(attachmentBytes!) : null,
      time: DateTime.now().toUtc(),
      isReaded: false
    );
    chatsRepository.sendMessage(message, attachmentBytes);
    messages?.add(message);
    channel.sendBroadcastMessage(
      event: 'new-message', 
      payload: message.toJSON()
    );

    attachmentBytes = null;
    setState(() {});
    messageController.text = '';
    focusNode.requestFocus();
    replyMessage = null;  
    scrollToBottomAnimated();
    sortMessages();
  }

  void onEditMessage() {
    final text = messageController.text.trim();
    if (text == '') return;
    for (Message message in messages!) {
      if (message.id == editingMessage!.id) message.text = text;
      break;
    }
    chatsRepository.editMessage(editingMessage!.id, text);
    channel.sendBroadcastMessage(event: 'edit-message', payload: {'messageID': editingMessage!.id, 'text': text});
    editingMessage = null;
    messageController.text = tmpMessage;
    setState(() {});
  }

  void onSetEditing(Message message) {
    editingMessage = message;
    tmpMessage = messageController.text.trim();
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
    tmpMessage = messageController.text.trim();
    messageController.text = '';
    setState(() {});
  }

  void onCancelReply() {
    replyMessage = null;
    messageController.text = tmpMessage;
    setState(() {});
  }

  void onDeleteMessage(Message message) {
    messages = messages?.where((mess) => message.id != mess.id).toList();
    setState(() {});
    sortMessages();
    chatsRepository.deleteMessage(message);
    channel.sendBroadcastMessage(event: 'delete-message', payload: {'messageID': message.id});
  }

  void onAttachImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Выбор изображения',
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg'],
      withData: true
    );

    if (result != null) {
      attachmentBytes = Uint8List.fromList(result.files.first.bytes!);
      setState(() {});
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 20)).then((_) => scrollController.jumpTo(scrollController.position.maxScrollExtent));
      return;
    }
    Future.delayed(Duration(milliseconds: 1)).then((val) => scrollToBottom());
  }

  void scrollToBottomAnimated() {
    if (scrollController.hasClients) {
      if (messages!.isNotEmpty && scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        Future.delayed(Duration(milliseconds: 30)).then((val) {
          if (mounted) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 250),
              curve: Curves.ease,
            );
          }
        });
      }
    }

    Future.delayed(Duration(milliseconds: 1)).then((val) => scrollToBottomAnimated());
  }

  void sortMessages() {
    if (messages != null) {
      for (int i = 0; i < messages!.length - 1; i++) {
        for (int j = 0; j < messages!.length - i - 1; j++) {
          if (messages![j].time.millisecondsSinceEpoch > messages![j + 1].time.millisecondsSinceEpoch) {
            Message tmp = messages![j];
            messages![j] = messages![j + 1];
            messages![j + 1] = tmp;
          }
        }
      }
      setState(() {});
    }
  }

  Future<void> onJoin() async {
    await teamsRepository.join(widget.chat.id);
    isMember = true;
    final user = (userBloc.state as UserStateLoaded).user;
    widget.chat.users.add(user);
    setState(() {});
  }

  @override
  void dispose() {
    focusNode.dispose();
    supabase.removeChannel(channel);
    super.dispose();
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
                            MessageWidget(
                              message: messages![i],
                              onEditMessage: onSetEditing,
                              onDeleteMessage: onDeleteMessage,
                              messages: messages!,
                              onReplyMessage: onSetReply,
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
                      return Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerWidget(height: 50, radius: 0),
                      );
                    },
                )
              ),
              Padding(
                padding: const EdgeInsets.all(0),
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
                      )
                      else if (replyMessage != null)
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
                                      replyMessage!.text != '' ? replyMessage!.text : 'отправленное изображение',
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
                      )
                      else if (attachmentBytes != null)
                      Container(
                        height: 150,
                        color: theme.canvasColor,
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 200,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: MemoryImage(attachmentBytes!),
                                    ),
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                          color: theme.colorScheme.error,
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                      child: Ink(
                                        child: InkWell(
                                          onTap: () => setState(() => attachmentBytes = null),
                                          customBorder: CircleBorder(),
                                          splashColor: theme.primaryColor,
                                          child: Icon(Icons.close, size: 20),
                                        ),
                                      ),
                                    ),
                                  )
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    if (isMember)
                    Container(
                      color: theme.canvasColor,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            IconButton(
                              color: theme.colorScheme.secondary,
                              onPressed: onAttachImage,
                              icon: Icon(Icons.attach_file, size: 28),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextFormField(
                                  keyboardType: TextInputType.multiline,
                                  controller: messageController,
                                  focusNode: focusNode,
                                  onFieldSubmitted: (_) {
                                    if (editingMessage != null) onEditMessage();
                                    else onSendMessage();
                                  },
                                  textInputAction: TextInputAction.search,
                                  minLines: 1,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hint: Text('Сообщение...'),
                                    border: InputBorder.none
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            if (editingMessage != null)
                              IconButton(
                                color: theme.colorScheme.secondary,
                                onPressed: onEditMessage,
                                icon: Icon(Icons.check, size: 28),
                              )
                            else
                              IconButton(
                                color: theme.colorScheme.secondary,
                                onPressed: onSendMessage,
                                icon: Icon(Icons.send, size: 28),
                              ),
                          ],
                        ),
                      )
                    )
                    else
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(onPressed: onJoin, child: Text('Присоединиться к чату', style: theme.textTheme.labelMedium)),
                      )
                    )
                  ],
                ),
              ),
            ],
          );
        } else if (state is UserStateError) {
          return Center(child: Text('Произошла ошибка при загрузке данных пользователя', style: theme.textTheme.titleMedium));
        }
        return SizedBox.shrink();
      },
    );
  }
}
