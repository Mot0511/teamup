import 'package:equatable/equatable.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/models/game.dart';

abstract class SearchEvent extends Equatable {}

class StartSearching extends SearchEvent {
  final User user;
  final SearchParams params;
  final Function(Team team) onTeamFormed;

  StartSearching({required this.user, required this.params, required this.onTeamFormed});

  @override
  List get props => [user, params, onTeamFormed]; 
}

class StopSearching extends SearchEvent {
  final User user;
  final SearchParams params;

  StopSearching({required this.user, required this.params});

  @override
  List get props => [user, params]; 
}