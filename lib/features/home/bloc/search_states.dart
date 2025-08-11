import 'package:equatable/equatable.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/models/game.dart';

abstract class SearchState extends Equatable {}

class SearchStateInitial extends SearchState {
    @override
    List get props => [];
}

class SearchStateSearching extends SearchState {
    final SearchParams params;
    
    SearchStateSearching({required this.params});

    @override
    List get props => [params];
}

class SearchStateSearchingFailure extends SearchState {
    final Exception e;
    
    SearchStateSearchingFailure({required this.e});

    @override
    List get props => [e];
}
