import 'package:equatable/equatable.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/models/game.dart';

abstract class SearchState extends Equatable {}

class SearchStateInitial extends SearchState {
  @override
  List get props => [];
}

class SearchStateReady extends SearchState {
  @override
  List get props => [];
}

class SearchStateSearching extends SearchState {
    final SearchParams params;
    
    SearchStateSearching({required this.params});

    @override
    List get props => [params];
}

class SearchStateError extends SearchState {
  final Exception e;
  
  SearchStateError({required this.e});

  @override
  List get props => [e];
}
