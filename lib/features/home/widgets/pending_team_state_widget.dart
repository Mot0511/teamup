import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/user/user.dart';

class PendingTeamStateWidget extends StatelessWidget {
  PendingTeamStateWidget({super.key, required this.currentTeamSize, required this.pendingUsers, required this.onStopSearching});
  final String currentTeamSize;
  final List<User> pendingUsers;
  final VoidCallback onStopSearching;
  
  final userBloc = GetIt.I<UserBloc>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Набрано игроков', 
                style: theme.textTheme.titleMedium
              ),
              Text(
                '${pendingUsers.length}/$currentTeamSize', 
                style: theme.textTheme.titleMedium
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: pendingUsers.map((User user) => 
                UserWidget(user: user)
              ).toList()
            )
          ),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onStopSearching,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                backgroundColor: theme.colorScheme.error
              ),
              child: Text("ОСТАНОВИТЬ ПОИСК", style: theme.textTheme.labelMedium)
            ),
          ),
          SizedBox(height: 15)
        ],
      ),
    );
  }
}