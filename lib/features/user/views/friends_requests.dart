import 'package:flutter/material.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';

class FriendRequests extends StatelessWidget {
  const FriendRequests({super.key, required this.users});
  final List<User> users;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Заявки в друзья')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: users.map((user) => UserWidget(user: user)).toList()
        ),
      )
    );
  }
}