import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamup/features/home/bloc/search_events.dart';
import 'package:teamup/features/home/bloc/search_states.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/home/repositories/repositories.dart';
import 'package:teamup/models/game.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required this.searchRepository}) : super(SearchStateInitial()) {
    on<GetReady>((event, emit) async {
      emit(SearchStateReady());
    });

    on<StartSearching>((event, emit) async {
      try {
        emit(SearchStateSearching(params: event.params));
        await searchRepository.startSearching(event.user, event.params);
      } on Exception catch (e) {
        emit(SearchStateError(e: e));
      }
    });

    on<StopSearching>((event, emit) async {
      try {
        emit(SearchStateReady());
        await searchRepository.stopSearching(event.user);
      } on Exception catch (e) {
        emit(SearchStateError(e: e));
      }
    });
    
    on<RestoreSearching>((event, emit) async {
      try {
        final SearchParams params = await searchRepository.restoreSearching(event.pendingTeamID);
        emit(SearchStateSearching(params: params));
      } on Exception catch (e) {
        emit(SearchStateError(e: e));
      }
    });
  
  }

  final SearchRepository searchRepository;
}