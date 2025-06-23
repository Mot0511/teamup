import 'package:flutter/material.dart';

class TeamWidget extends StatelessWidget {
  const TeamWidget({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(id), 
      background: Container(color: Colors.red),
      child: ListTile(
        onTap: () {},
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(50)
          ),
        ),
        title: Text('Название команды', style: theme.textTheme.labelMedium),
        subtitle: Text('10 участников', style: theme.textTheme.labelSmall),
        trailing: IconButton(
          onPressed: () {},
          icon: Icon(Icons.logout, color: Colors.red, size: 35)
        ),
      )
    );
  }
}