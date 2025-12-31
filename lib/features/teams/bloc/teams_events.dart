import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';

abstract class TeamsEvent extends Equatable {}

class LoadTeams extends TeamsEvent {
  final String uid;
  final Completer? completer;
  LoadTeams({required this.uid, this.completer});

  @override
  List get props => [uid];
}

class AddTeam extends TeamsEvent {
  final Team team;
  final Uint8List? choosenIconBytes; 

  AddTeam({required this.team, required this.choosenIconBytes});

  @override
  List get props => [team, choosenIconBytes];
}

class EditTeam extends TeamsEvent {
  final Team team;
  final List<User> addedMembers;
  final List<User> removedMembers;

  EditTeam({
    required this.team,
    required this.addedMembers,
    required this.removedMembers
  });

  @override
  List get props => [team, addedMembers, removedMembers];
}

class RemoveTeam extends TeamsEvent {
  final Team team;
  final String uid;

  RemoveTeam({required this.team, required this.uid});

  @override
  List get props => [team];
}

class ClearTeams extends TeamsEvent {
  @override
  List get props => [];
}