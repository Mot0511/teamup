import 'dart:io';
import 'dart:typed_data';

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
  
  UpdateUser({required this.user});

  @override
  List get props => [user];
}

class Signout extends UserEvent {
  @override
  List get props => [];
}