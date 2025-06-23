import 'package:equatable/equatable.dart';
import 'package:teamup/features/user/models/models.dart';

abstract class UserState extends Equatable {}

class UserStateInitial extends UserState {
  @override
  List get props => [];
}

class UserStateLoading extends UserState {
  @override
  List get props => [];
}

class UserStateLoaded extends UserState {
  final User user;

  UserStateLoaded({required this.user});

  @override
  List get props => [user];
}

class UserStateError extends UserState {
  final Object e;

  UserStateError({required this.e});

  @override
  List get props => [e];
}