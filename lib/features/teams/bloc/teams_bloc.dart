import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';

class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  TeamsBloc({required this.teamsRepository}) : super(TeamsStateInitial()) {
    on<LoadPublicTeams>((event, emit) async {
      List<Team> privateTeams = [];
      if (state is TeamsStateLoaded) {
        privateTeams = (state as TeamsStateLoaded).privateTeams;
      }
      if (event.completer == null) emit(TeamsStateLoading());
      try {
        final List<Team> publicTeams = await teamsRepository.getTeams();
        emit(TeamsStateLoaded(publicTeams: publicTeams, privateTeams: privateTeams));
        event.completer?.complete();
      } on Exception catch (e) {
        emit(TeamsStateError(e: e));
      }
    });

    on<LoadPrivateTeams>((event, emit) async {
      List<Team> publicTeams = [];
      if (state is TeamsStateLoaded) {
        publicTeams = (state as TeamsStateLoaded).publicTeams;
      }
      if (event.completer == null) emit(TeamsStateLoading());
      try {
        final List<Team> privateTeams = await teamsRepository.getTeams(event.uid);
        emit(TeamsStateLoaded(publicTeams: publicTeams, privateTeams: privateTeams));
        event.completer?.complete();
      } on Exception catch (e) {
        emit(TeamsStateError(e: e));
      }
    });

    on<AddTeam>((event, emit) async {
      if (state is TeamsStateLoaded) {
        try {
          if (event.choosenIconBytes != null) {
            teamsRepository.uploadIcon(event.team.id, event.choosenIconBytes!);
          }
          await teamsRepository.addTeam(event.team);

          final List<Team> publicTeams = (state as TeamsStateLoaded).publicTeams;
          final List<Team> privateTeams = (state as TeamsStateLoaded).privateTeams;
          emit(TeamsStateInitial());
          if (event.team.isPublic) {
            publicTeams.add(event.team);
          } else {
            privateTeams.add(event.team);
          }
          emit(TeamsStateLoaded(publicTeams: publicTeams, privateTeams: privateTeams));
        } on Exception catch (e) {
          emit(TeamsStateError(e: e));
        }
      }
    });

    on<EditTeam>((event, emit) async {
      List<Team> publicTeams = [];
      if (state is TeamsStateLoaded) {
        publicTeams = (state as TeamsStateLoaded).publicTeams;
      }
      if (state is TeamsStateLoaded) {
        try {
          final List<Team> privateTeams = (state as TeamsStateLoaded).privateTeams;
          emit(TeamsStateLoading());
          for (var i = 0; i < privateTeams.length; i++) {
            if (privateTeams[i].id == event.team.id) {
              privateTeams[i] = event.team;
              break;
            }
          }
          await teamsRepository.editTeam(event.team, event.addedMembers, event.removedMembers);
          emit(TeamsStateLoaded(publicTeams: publicTeams, privateTeams: privateTeams));
        } on Exception catch (e) {
          emit(TeamsStateError(e: e));
        }
      }
    });

    on<RemoveTeam>((event, emit) async {
      if (state is TeamsStateLoaded) {
        try {
          List<Team> publicTeams = (state as TeamsStateLoaded).publicTeams;
          List<Team> privateTeams = (state as TeamsStateLoaded).privateTeams;
          await teamsRepository.removeTeam(event.team, event.uid);
          emit(TeamsStateInitial());
          if (event.team.isPublic) {
            for (Team publicTeam in publicTeams) {
              if (publicTeam.id == event.team.id) {
                publicTeam.users = publicTeam.users.where((user) => user.uid != event.uid).toList();
              }
            }
          } else {
            privateTeams = privateTeams.where((chat) => chat.id != event.team.id).toList();
          }
          emit(TeamsStateLoaded(publicTeams: publicTeams, privateTeams: privateTeams));
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