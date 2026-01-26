import 'package:equatable/equatable.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/user/user.dart';

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