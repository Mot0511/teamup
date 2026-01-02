import 'package:flutter/material.dart';
import 'package:teamup/features/home/models/update_info.dart';
import 'package:teamup/features/home/views/update_info_view.dart';

class UpdateMessageWidget extends StatelessWidget implements PreferredSizeWidget {
  UpdateMessageWidget({super.key, required this.updateInfo});
  final UpdateInfo updateInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Вышло обновление 1.0.1', style: theme.textTheme.titleSmall),
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