import 'dart:async';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';

abstract class TeamsEvent extends Equatable {}

class LoadPublicTeams extends TeamsEvent {
  final Completer? completer;
  LoadPublicTeams({this.completer});

  @override
  List get props => [completer];
}


class LoadPrivateTeams extends TeamsEvent {
  final String uid;
  final Completer? completer;
  LoadPrivateTeams({required this.uid, this.completer});

  @override
  List get props => [uid, completer];
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