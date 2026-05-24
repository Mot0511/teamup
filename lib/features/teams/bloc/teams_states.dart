import 'package:equatable/equatable.dart';
import 'package:teamup/features/teams/teams.dart';

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
  final List<Team> publicTeams;
  final List<Team> privateTeams;

  TeamsStateLoaded({required this.publicTeams, required this.privateTeams});

  @override
  List get props => [publicTeams, privateTeams];
}

class TeamsStateError extends TeamsState {
  final Exception e;

  TeamsStateError({required this.e});

  @override
  List get props => [e];
}