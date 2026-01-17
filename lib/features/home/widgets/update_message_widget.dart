import 'package:flutter/material.dart';
import 'package:teamup/features/home/home.dart';

class UpdateMessageWidget extends StatelessWidget implements PreferredSizeWidget {
  const UpdateMessageWidget({super.key, required this.updateInfo});
  final UpdateInfo updateInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Вышло обновление ${updateInfo.currentVersion}', style: theme.textTheme.titleSmall),
          SizedBox(width: 10),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateInfoView(updateInfo: updateInfo))),
            child: Text('Загрузить сейчас', style: theme.textTheme.titleSmall?.copyWith(color: theme.primaryColor))
          ),
        ],
      )
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(20.0);
}