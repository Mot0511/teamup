import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/chats/utils/get_user_from_members.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/services/realtime_service.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class MessengerWidget extends StatefulWidget {
  const MessengerWidget({super.key, required this.chat});
  final Chat chat;

  @override
  State<MessengerWidget> createState() => _MessengerWidgetState();
}

class _MessengerWidgetState extends State<MessengerWidget> {
  final realtime = GetIt.I<RealtimeService>();
  final userBloc = GetIt.I<UserBloc>();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  final messageController = TextEditingController();
  final focusNode = FocusNode();
  final scrollController = ScrollController();

  List<Message>? messages;
  void Function()? _chatUnsub;

  Message? editingMessage;
  Message? replyMessage;
  String tmpMessage = '';
  Uint8List? attachmentBytes;
  final List<Uint8List> pendingAttachments = [];

  bool isMember = false;

  String? currentUid() {
    final state = userBloc.state;
    if (state is UserStateLoaded) return state.user.uid;
    return null;
  }

  @override
  void initState() {
    super.initState();
    checkIsMember();
    loadMessages();
    listenMessages();
  }

  void checkIsMember() {
    final String? uid = currentUid();
    if (uid == null) return;
    isMember = widget.chat.users.map((user) => user.uid).toList().contains(uid);
    setState(() {});
  }

  Future<void> loadMessages() async {
    messages = await chatsRepository.getMessages(widget.chat.id);
    _sortMessagesInPlace();
    setMessagesReaded();
    setState(() {});
    scrollToBottom();
  }

  Future<void> setMessagesReaded() async {
    final uid = currentUid();
    if (uid == null) return;
    if (messages == null) return;
    for (Message message in messages!) {
      if (message.user.uid != uid && !message.isReaded) {
        await chatsRepository.setReaded(widget.chat.id, message);
      }
    }
  }

  void listenMessages() {
    _chatUnsub = realtime.subscribe('/topic/chats/${widget.chat.id}', (payload) async {
      if (payload is! Map<String, dynamic>) return;
      final event = payload['event'];
      switch (event) {
        case 'SEND':
          await onMessageSend(payload['payload'] as Map<String, dynamic>);
          break;
        case 'EDIT':
          onMessageEdit(payload['payload'] as Map<String, dynamic>);
          break;
        case 'DELETE':
          onMessageDelete((payload['payload']['id'] as num).toInt());
          break;
        case 'READ':
          onMessageRead((payload['payload']['id'] as num).toInt());
          break;
      }
    });
  }

  Future<void> onMessageSend(Map<String, dynamic> data) async {
    final String? uid = currentUid();

    final User sender = getUserFromMembers(data['uid'], widget.chat.users);

    final Message message = Message.fromJSON(data, sender: sender);

    if (messages?.any((m) => m.id == message.id) ?? false) return;

    if (uid != null && message.user.uid == uid) {
      // Своё сообщение ещё не прочитано собеседником — отметка придёт
      // событием READ из /topic/chats/{id}.
      message.isReaded = false;
      if (pendingAttachments.isNotEmpty) {
        final bytes = pendingAttachments.removeAt(0);
        await uploadAttachment(message.id, bytes);
      }
    } else {
      await chatsRepository.setReaded(widget.chat.id, message);
      message.isReaded = true;
    }

    messages?.add(message);
    if (mounted) setState(() {});
    scrollToBottomAnimated();
    sortMessages();
  }

  Future<void> uploadAttachment(int messageID, Uint8List bytes) async {
    try {
      await chatsRepository.uploadAttachment(bytes, messageID);
      final provider = await chatsRepository.getAttachment(messageID);
      if (messages == null) return;
      for (int i = messages!.length - 1; i >= 0; i--) {
        if (messages![i].id == messageID) {
          messages![i].attachment = provider;
          if (mounted) setState(() {});
          break;
        }
      }
    } on Exception catch (e) {
      debugPrint('Failed to upload attachment: $e');
    }
  }

  void onMessageEdit(Map<String, dynamic> data) {
    final int messageId = (data['id'] as num).toInt();
    final String text = '${data['text'] ?? ''}';
    if (messages == null) return;
    for (int i = messages!.length - 1; i >= 0; i--) {
      if (messages![i].id == messageId) {
        messages![i].text = text;
        break;
      }
    }
    setState(() {});
  }

  void onMessageDelete(int messageId) {
    messages = messages?.where((message) => message.id != messageId).toList();
    setState(() {});
    sortMessages();
  }

  void onMessageRead(int messageId) {
    if (messages == null) return;
    for (int i = messages!.length - 1; i >= 0; i--) {
      final Message message = messages![i];
      if (message.id == messageId) {
        message.isReaded = true;
        setState(() {});
        break;
      }
    }
  }

  Future<void> onSendMessage() async {
    final String text = messageController.text.trim();
    if (text == '' && attachmentBytes == null) return;

    final int? repliedId = replyMessage?.id;
    final Uint8List? bytesToSend = attachmentBytes;
    if (bytesToSend != null) {
      pendingAttachments.add(bytesToSend);
    }

    attachmentBytes = null;
    setState(() {});
    messageController.text = '';
    focusNode.requestFocus();
    replyMessage = null;

    await chatsRepository.sendMessage(widget.chat.id, text, repliedId);
  }

  void onEditMessage() {
    final String text = messageController.text.trim();
    if (text == '') return;
    if (editingMessage == null) return;
    final int id = editingMessage!.id;
    editingMessage!.text = text;
    if (messages != null) {
      for (Message message in messages!) {
        if (message.id == id) {
          message.text = text;
          break;
        }
      }
    }
    chatsRepository.editMessage(widget.chat.id, editingMessage!);
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
    chatsRepository.deleteMessage(widget.chat.id, message);
  }

  Future<void> onAttachImage() async {
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
    void jumpToEnd() {
      if (!mounted || !scrollController.hasClients) return;
      final max = scrollController.position.maxScrollExtent;
      scrollController.jumpTo(max);
    }

    void afterLayout() {
      if (!mounted) return;
      if (!scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => afterLayout());
        return;
      }
      jumpToEnd();
      WidgetsBinding.instance.addPostFrameCallback((_) => jumpToEnd());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => afterLayout());
  }

  void scrollToBottomAnimated() {
    void animate() {
      if (!mounted || !scrollController.hasClients || messages == null || messages!.isEmpty) {
        return;
      }
      final max = scrollController.position.maxScrollExtent;
      scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => animate());
      } else {
        animate();
      }
    });
  }

  void _sortMessagesInPlace() {
    if (messages == null) return;
    for (int i = 0; i < messages!.length - 1; i++) {
      for (int j = 0; j < messages!.length - i - 1; j++) {
        if (messages![j].time.millisecondsSinceEpoch > messages![j + 1].time.millisecondsSinceEpoch) {
          final Message tmp = messages![j];
          messages![j] = messages![j + 1];
          messages![j + 1] = tmp;
        }
      }
    }
  }

  void sortMessages() {
    if (messages != null) {
      _sortMessagesInPlace();
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
    _chatUnsub?.call();
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
                            if (i == 0 || i > 0 &&
                              (messages![i].time.day != messages![i - 1].time.day ||
                              messages![i].time.month != messages![i - 1].time.month ||
                              messages![i].time.year != messages![i - 1].time.year))
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
                                  onFieldSubmitted: (_) async {
                                    if (editingMessage != null) onEditMessage();
                                    else await onSendMessage();
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
                                onPressed: () async => await onSendMessage(),
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