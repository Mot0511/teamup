import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:teamup/features/user/models/friendship.dart';
import 'package:teamup/features/user/models/models.dart';

abstract class UserEvent extends Equatable {}

class LoadUser extends UserEvent {
  final String uid;

  LoadUser({required this.uid});

  @override
  List get props => [uid];
}

class UpdateUser extends UserEvent {
  final User user;
  final File? choosenAvatar;
  
  UpdateUser({required this.user, required this.choosenAvatar});

  @override
  List get props => [user, choosenAvatar];
}

class AddFriend extends UserEvent {
  final Friendship friendship;

  AddFriend({required this.friendship});

  @override
  List get props => [friendship];
}

class AllowFriendRequest extends UserEvent {
  final Friendship friendship;

  AllowFriendRequest({required this.friendship});

  @override
  List get props => [friendship];
}

class RemoveFriend extends UserEvent {
  final Friendship friendship;

  RemoveFriend({required this.friendship});

  @override
  List get props => [friendship];
}