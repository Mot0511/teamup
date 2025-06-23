import 'package:flutter/material.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {

  bool isMuted = true;
  bool isSound = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text('Имя пользователя', style: theme.textTheme.labelMedium),
          subtitle: Text('В сети', style: theme.textTheme.labelSmall),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => isMuted = !isMuted),
            icon: Icon(isMuted ? Icons.phone_enabled : Icons.phone_disabled)
          ),
          IconButton(
            onPressed: () => setState(() => isSound = !isSound),
              icon: Icon(isSound ? Icons.headset_mic : Icons.headset_off)
            ),
        ],
      ),
    );
  }
}