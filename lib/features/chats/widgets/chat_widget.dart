import 'package:flutter/material.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(id), 
      background: Container(color: Colors.red),
      child: ListTile(
        onTap: () {},
        leading: AvatarWidget(uid: '123', size: 50),
        title: Text('Имя пользователя', style: theme.textTheme.labelMedium),
        subtitle: Text('Последнее сообщение', style: theme.textTheme.labelSmall),
      )
    );
  }
}