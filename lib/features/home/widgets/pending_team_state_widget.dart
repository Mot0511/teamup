import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';

class PendingTeamStateWidget extends StatelessWidget {
  PendingTeamStateWidget({super.key, required this.currentTeamSize, required this.pendingUsers});
  final String currentTeamSize;
  final List<User> pendingUsers;
  
  final userBloc = GetIt.I<UserBloc>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Идет поиск...', 
                style: theme.textTheme.titleLarge
              ),
              Text(
                '${pendingUsers.length}/$currentTeamSize', 
                style: theme.textTheme.titleLarge
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
          )
        ],
      ),
    );
  }
}