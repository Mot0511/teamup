import 'package:equatable/equatable.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/models/game.dart';

abstract class SearchEvent extends Equatable {}

class GetReady extends SearchEvent {
  @override
  List get props => [];
}

class StartSearching extends SearchEvent {
  final User user;
  final SearchParams params;

  StartSearching({
    required this.user, 
    required this.params, 
  });

  @override
  List get props => [user, params]; 
}

class StopSearching extends SearchEvent {
  final User user;

  StopSearching({required this.user});

  @override
  List get props => [user]; 
}

class RestoreSearching extends SearchEvent {
  final int pendingTeamID;

  RestoreSearching({required this.pendingTeamID});

  @override
  List get props => [pendingTeamID]; 
}