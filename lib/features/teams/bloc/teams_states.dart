import 'package:equatable/equatable.dart';
import 'package:teamup/features/teams/models/team.dart';

abstract class TeamsState extends Equatable {}

class TeamsStateInitial extends TeamsState {
  @override
  List get props => [];
}

class TeamsStateLoading extends TeamsState {
  @override
  List get props => [];
}

class TeamsStateLoaded extends TeamsState {
  final List<Team> teams;

  TeamsStateLoaded({required this.teams});

  @override
  List get props => [teams];
}

class TeamsStateError extends TeamsState {
  final Object e;

  TeamsStateError({required this.e});

  @override
  List get props => [e];
}