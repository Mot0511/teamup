import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamup/features/teams/teams.dart';

class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  TeamsBloc({required this.teamsRepository}) : super(TeamsStateInitial()) {
    on<LoadTeams>((event, emit) async {
      if (event.completer == null) emit(TeamsStateLoading());
      try {
        final teams = await teamsRepository.getTeams(event.uid);
        emit(TeamsStateLoaded(teams: teams));
        event.completer?.complete();
      } on Exception catch (e) {
        emit(TeamsStateError(e: e));
      }
    });

    on<AddTeam>((event, emit) async {
      if (state is TeamsStateLoaded) {
        try {
          final List<Team> teams = (state as TeamsStateLoaded).teams;
          if (event.choosenIconBytes != null) {
            teamsRepository.uploadIcon(event.team.id, event.choosenIconBytes!);
          }
          await teamsRepository.addTeam(event.team);
          emit(TeamsStateInitial());
          teams.add(event.team);
          emit(TeamsStateLoaded(teams: teams));
        } on Exception catch (e) {
          emit(TeamsStateError(e: e));
        }
      }
    });

    on<EditTeam>((event, emit) async {
      if (state is TeamsStateLoaded) {
        try {
          final List<Team> teams = (state as TeamsStateLoaded).teams;
          emit(TeamsStateLoading());
          for (var i = 0; i < teams.length; i++) {
            if (teams[i].id == event.team.id) {
              teams[i] = event.team;
              break;
            }
          }
          await teamsRepository.editTeam(event.team, event.addedMembers, event.removedMembers);
          emit(TeamsStateLoaded(teams: teams));
        } on Exception catch (e) {
          emit(TeamsStateError(e: e));
        }
      }
    });

    on<RemoveTeam>((event, emit) async {
      if (state is TeamsStateLoaded) {
        try {
          final List<Team> chats = (state as TeamsStateLoaded).teams;
          await teamsRepository.removeTeam(event.team, event.uid);
          emit(TeamsStateInitial());
          chats.remove(event.team);
          emit(TeamsStateLoaded(teams: chats));
        } on Exception catch (e) {
          emit(TeamsStateError(e: e));
        }
      }
    });

    on<ClearTeams>((event, emit) async {
      emit(TeamsStateInitial());
    });


  }

  final TeamsRepository teamsRepository;
}