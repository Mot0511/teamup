import 'package:flutter/material.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  bool isMuted = true;
  bool isSound = true;
  final TextEditingController messageController = TextEditingController();
  List messages = [];

  void enterMessage() {
    setState(() {
      if (messageController.text.isNotEmpty) {
        messages.add(messageController.text);
        messageController.clear(); // Очищаем поле ввода
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text('Имя', style: theme.textTheme.labelMedium),
          subtitle: Text('В сети', style: theme.textTheme.labelSmall),
          leading: AvatarWidget(uid: '123', size: 50),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => isMuted = !isMuted),
            icon: Icon(isMuted ? Icons.phone_enabled : Icons.phone_disabled),
          ),
          IconButton(
            onPressed: () => setState(() => isSound = !isSound),
            icon: Icon(isSound ? Icons.headset_mic : Icons.headset_off),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(10),
                      color: theme.cardColor,
                    ),
                    padding: EdgeInsets.all(5),
                    child: Text(messages[index]),
                  ),

                  leading: AvatarWidget(uid: '123', size: 35),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 35,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Enter a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsGeometry.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.green,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.telegram),
                      onPressed: enterMessage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
