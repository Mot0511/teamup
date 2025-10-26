import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/teams/bloc/teams_bloc.dart';
import 'package:teamup/features/teams/bloc/teams_events.dart';
import 'package:teamup/features/teams/bloc/teams_states.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/teams/views/create_team_view.dart';
import 'package:teamup/features/teams/widgets/team_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class TeamsView extends StatefulWidget {
  const TeamsView({super.key});

  @override
  State<TeamsView> createState() => _TeamsViewState();
}

class _TeamsViewState extends State<TeamsView> {

  final teamsRepository = GetIt.I<TeamsRepository>();
  final teamsBloc = GetIt.I<TeamsBloc>();
  final userBloc = GetIt.I<UserBloc>();

  @override
  void initState() {
    super.initState();

    loadTeams();
    userBloc.stream.listen((state) {
      loadTeams();
    });
  }

  void loadTeams({Completer? completer}) {
    if ((teamsBloc.state is TeamsStateInitial || completer != null) && userBloc.state is UserStateLoaded) {
      teamsBloc.add(LoadTeams(uid: (userBloc.state as UserStateLoaded).user.uid, completer: completer));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Команды'),
        actions: [
          if (!Platform.isAndroid)
          IconButton(onPressed: () {
            final completer = Completer();
            loadTeams(completer: completer);
          }, icon: Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final completer = Completer();
                loadTeams(completer: completer);
                return completer.future;
              },
              child: BlocBuilder(
                bloc: teamsBloc,
                builder: (context, state) {
                  if (state is TeamsStateLoaded) {
                    if (state.teams.isNotEmpty) {
                      return ListView(
                        children: state.teams.map((team) => TeamWidget(team: team)).toList(),
                      );
                    } else {
                      return CustomScrollView(
                        shrinkWrap: true,
                        slivers: [
                          SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('У тебя нет личных чатов', style: theme.textTheme.titleMedium),
                          ),
                        ),
                        ],
                      );
                    }
                  } else if (state is TeamsStateError) {
                    return Center(child: Text('Произошла ошибка при загрузке команд', textAlign: TextAlign.center, style: theme.textTheme.titleMedium));
                  } else {
                    return ListView.builder(
                      itemCount: 3 + Random().nextInt(5),
                      itemBuilder: (context, state) => 
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: SihmmerWidget(),
                        )
                    );
                  }
                }
              )
            )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTeamView())),
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}