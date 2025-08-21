import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamup/features/teams/bloc/teams_events.dart';
import 'package:teamup/features/teams/bloc/teams_states.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/teams_repository.dart';

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
        final List<Team> teams = (state as TeamsStateLoaded).teams;
        emit(TeamsStateLoading());
        await teamsRepository.addTeam(event.team);
        if (event.choosenIcon != null){
          await teamsRepository.uploadIcon(event.team.id, event.choosenIcon as File);
        }
        teams.add(event.team);
        
        emit(TeamsStateLoaded(teams: teams));
      }
    });

    on<EditTeam>((event, emit) async {
      if (state is TeamsStateLoaded) {
        final List<Team> teams = (state as TeamsStateLoaded).teams;
        emit(TeamsStateLoading());
        for (var i = 0; i < teams.length; i++) {
          if (teams[i].id == event.team.id) {
            teams[i] = event.team;
            break;
          }
        }
        await teamsRepository.editTeam(event.team, event.addedMembers, event.removedMembers);
        if (event.choosenIcon != null){
          await teamsRepository.uploadIcon(event.team.id, event.choosenIcon as File);
        }
        emit(TeamsStateLoaded(teams: teams));
      }
    });

    on<RemoveTeam>((event, emit) async {
      if (state is TeamsStateLoaded) {
        final List<Team> chats = (state as TeamsStateLoaded).teams;
        emit(TeamsStateLoading());
        await teamsRepository.removeTeam(event.team, event.uid);
        chats.remove(event.team);
        emit(TeamsStateLoaded(teams: chats));
      }
    });

    on<ClearTeams>((event, emit) async {
      emit(TeamsStateInitial());
    });


  }

  final TeamsRepository teamsRepository;
}