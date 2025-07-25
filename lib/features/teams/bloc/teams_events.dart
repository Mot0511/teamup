import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';

abstract class TeamsEvent extends Equatable {}

class LoadTeams extends TeamsEvent {
  final String uid;
  LoadTeams({required this.uid});

  @override
  List get props => [uid];
}

class AddTeam extends TeamsEvent {
  final Team team;
  final File? choosenIcon; 

  AddTeam({required this.team, required this.choosenIcon});

  @override
  List get props => [team];
}

class EditTeam extends TeamsEvent {
  final Team team;
  final File? choosenIcon;
  final List<User> addedMembers;
  final List<User> removedMembers;

  EditTeam({
    required this.team,
    required this.choosenIcon,
    required this.addedMembers,
    required this.removedMembers
  });

  @override
  List get props => [team];
}

class RemoveTeam extends TeamsEvent {
  final Team team;
  final String uid;

  RemoveTeam({required this.team, required this.uid});

  @override
  List get props => [team];
}