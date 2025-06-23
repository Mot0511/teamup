import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/enums.dart';
import 'package:teamup/features/user/models/friendship.dart';
import 'package:teamup/features/user/models/user.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/views/views.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';
import 'package:teamup/providers/global_provider.dart';

class ProfileView extends StatefulWidget {
  ProfileView({super.key, this.user});
  final User? user;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final userBloc = GetIt.I<UserBloc>();

  final userRepository = GetIt.I<UserRepository>();

  FriendState? friendState;
  List<User> friends = [];

  void loadFriends() async {
    if (userBloc.state is UserStateLoaded) {
      final state = (userBloc.state as UserStateLoaded);
      final List<Friendship> friendships = await userRepository.getFriends(
        widget.user != null ? widget.user!.uid : state.user.uid
      );
      for (var friendship in friendships) {
        if (friendship.state == FriendState.friend) {
          friends.add(friendship.friend);
        }
        if (friendship.friend.uid == state.user.uid) {
          friendState = friendship.state;
        }
      }
      friendState ??= FriendState.notFriend;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    loadFriends();
  }

  void addFriendHandler(User user) async {
    await userRepository.addFriend(user, (widget.user as User));
    if (friendState == FriendState.notFriend) {
      friendState = FriendState.requestedToMe;
    } else if (friendState == FriendState.iRequested) {
      friendState = FriendState.friend;
    }
    setState(() {});
    
  }
  
  void removeFriendHandler(String uid) async {
    await userRepository.removeFriend(uid);
    friendState = FriendState.notFriend;
    setState(() {});
  }

  void logoutHandler(context) async {
    await userRepository.signout();
    Provider.of<GlobalProvider>(context, listen: false).setIsLogined = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user != null ? 'Профиль ${widget.user?.username}' : 'Мой профиль'),
        actions: [
          BlocBuilder(
            bloc: userBloc,
            builder: (context, state) {
              if (widget.user == null) {
                return Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileView(user: (userBloc.state as UserStateLoaded).user))), 
                      icon: Icon(Icons.edit)
                    ),
                    IconButton(
                      onPressed: () => logoutHandler(context), 
                      icon: Icon(Icons.logout)
                    ),
                  ],
                );
              } else {
                return SizedBox.shrink();
              }
            }
          )
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        bloc: userBloc,
        builder: (context, state) {
          if (state is UserStateLoaded) {
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 100),
                            AvatarWidget(uid: widget.user != null ? widget.user!.uid : state.user.uid, size: 150),
                            SizedBox(height: 10),
                            Text(widget.user != null ? widget.user!.username : state.user.username, style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
                            SizedBox(height: 10),
                            if (widget.user?.description != null || (widget.user == null && state.user.description != null))
                            Text(widget.user != null ? (widget.user?.description as String) : (state.user.description as String), style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                            SizedBox(height: 20),
                            widget.user != null && widget.user?.uid != state.user.uid
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {}, 
                                    child: Row(
                                      children: [
                                        Icon(Icons.chat, color: Colors.white, size: 35),
                                      ],
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(15),
                                      backgroundColor: theme.primaryColor
                                    )
                                  ),
                                  SizedBox(width: 10),
                                  friendState != null
                                    ? friendState == FriendState.notFriend
                                      ? ElevatedButton(
                                          onPressed: () => addFriendHandler(state.user),
                                          child: Row(
                                            children: [
                                              Icon(Icons.group_add, color: Colors.white, size: 25),
                                              SizedBox(width: 5),
                                              Text('Добавить в друзья', style: theme.textTheme.labelMedium)
                                            ],
                                          )
                                        )
                                      : friendState == FriendState.iRequested
                                        ? ElevatedButton(
                                          onPressed: () => addFriendHandler(state.user),
                                          child: Row(
                                            children: [
                                              Icon(Icons.group_add, color: Colors.white, size: 25),
                                              SizedBox(width: 5),
                                              Text('Принять заявку в друзья', style: theme.textTheme.labelMedium)
                                            ],
                                          )
                                        )
                                        : friendState == FriendState.requestedToMe
                                          ? OutlinedButton(
                                            onPressed: () => removeFriendHandler(state.user.uid),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: theme.primaryColor)
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.group_add, color: Colors.white, size: 25),
                                                SizedBox(width: 5),
                                                Text('Заявка отправлена', style: theme.textTheme.labelMedium)
                                              ],
                                            )
                                          )
                                          : OutlinedButton(
                                              onPressed: () => removeFriendHandler(state.user.uid), 
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: Colors.red)
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.group_add, color: Colors.white, size: 25),
                                                  SizedBox(width: 5),
                                                  Text('Удалить из друзей', style: theme.textTheme.labelMedium)
                                                ],
                                              )
                                            )
                                    : SizedBox.shrink()
                                ],
                              )
                            : SizedBox.shrink()
                            
                          ],
                        )
                      ),
                      SizedBox(height: 50),
                      Text('Друзья ${state.user.username}', style: theme.textTheme.titleLarge),
                      SizedBox(height: 20),
                      
                    ],
                  ),
                ),
                // Column(
                //   children: List.generate(5, (i) => UserWidget(id: i.toString()))
                // )
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }
      )
    );
  }
}