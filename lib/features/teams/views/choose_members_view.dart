import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/enums.dart';
import 'package:teamup/features/user/models/friendship.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';

class ChooseMembersView extends StatefulWidget {
  const ChooseMembersView({super.key});

  @override
  State<ChooseMembersView> createState() => _ChooseMembersViewState();
}

class _ChooseMembersViewState extends State<ChooseMembersView> {

  List<User> members = [];
  List<User>? friends;
  final userRepository = GetIt.I<UserRepository>();
  final userBloc = GetIt.I<UserBloc>();
  
  void loadFriends() async {
    if (userBloc.state is UserStateLoaded) {
      final List<User> _friends = [];
      final List<Friendship> friendships = await userRepository.getFriends((userBloc.state as UserStateLoaded).user.uid);
      for (Friendship friendship in friendships) {
        if (friendship.state == FriendState.friend) {
          _friends.add(friendship.friend);
        }
      }
      friends = _friends;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Добавить тиммейта')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: friends != null
                ? friends!.isNotEmpty
                  ? ListView(
                      children: friends!.map((friend) => UserWidget(
                        user: friend,
                        trailing: members.contains(friend)
                          ? IconButton(
                              onPressed: () => setState(() => members.remove(friend)),
                              icon: Icon(Icons.check, size: 40, color: Colors.green)
                            )
                          : IconButton(
                            onPressed: () => setState(() => members.add(friend)),
                            icon: Icon(Icons.add, size: 40)
                          )
                      )).toList()
                    )
                  : Center(child: Text('У вас нет друзей'))
                : Center(child: CircularProgressIndicator()),
            )
          ),
           Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, members),
              child: Text('Добавить участников', style: theme.textTheme.labelMedium)
            )
          ),
          SizedBox(height: 50)
        ],
      ),
    );
  }
}