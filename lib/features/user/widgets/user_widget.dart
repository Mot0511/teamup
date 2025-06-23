import 'package:flutter/material.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/views/profile_view.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';

class UserWidget extends StatelessWidget {
  const UserWidget({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileView(user: user))),
      leading: AvatarWidget(uid: user.uid, size: 45),
      title: Text(user.username, style: theme.textTheme.labelLarge),
    );
  }
}