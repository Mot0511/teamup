import 'package:equatable/equatable.dart';
import 'package:teamup/features/user/user.dart';

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