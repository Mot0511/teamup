import 'package:flutter/material.dart';
import 'package:teamup/features/chats/widgets/chat_widget.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Личные чаты')),
      body: ListView(
        children: List.generate(5, (i) => ChatWidget(id: i.toString()))
      ),
    );
  }
}