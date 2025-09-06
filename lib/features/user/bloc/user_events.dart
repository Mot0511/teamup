import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
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

class Signout extends UserEvent {
  @override
  List get props => [];
}