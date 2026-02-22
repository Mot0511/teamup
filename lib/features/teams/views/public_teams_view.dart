import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class PublicTeamsView extends StatefulWidget {
  const PublicTeamsView({super.key});

  @override
  State<PublicTeamsView> createState() => _PublicTeamsViewState();
}

class _PublicTeamsViewState extends State<PublicTeamsView> {

  final teamsRepository = GetIt.I<TeamsRepository>();
  final userBloc = GetIt.I<UserBloc>();
  final teamsBloc = GetIt.I<TeamsBloc>();
  List<Team>? teams;
  bool isError = false;

  @override
  void initState() {
    super.initState();

    loadPublicTeams();
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

  Future<void> loadPublicTeams([Completer? completer]) async {
    teams = null;
    setState(() {});

    try {
      teams = await teamsRepository.getTeams();
    } on Exception catch (_) {
      isError = true;
    }
    
    setState(() {});
    if (completer != null) {
      completer.complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Публичные команды'),
        actions: [
          if (kIsWeb || !Platform.isAndroid)
          IconButton(onPressed: () {
            loadPublicTeams();
          }, icon: Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final completer = Completer();
                loadPublicTeams(completer);
                return completer.future;
              },
              child: teams != null
                ? teams!.isNotEmpty
                  ? ListView(
                      children: teams!.map((team) => TeamWidget(team: team)).toList(),
                    )
                  : CustomScrollView(
                      shrinkWrap: true,
                        slivers: [
                          SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('Пока нет никаких публичных команд\nМожет создашь одну?', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                          ),
                        ),
                      ],
                    )
                : isError
                  ? Center(child: Text('Произошла ошибка при загрузке команд', textAlign: TextAlign.center, style: theme.textTheme.titleMedium))
                  : ListView.builder(
                    itemCount: 3 + Random().nextInt(5),
                    itemBuilder: (context, state) => 
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: ShimmerWidget(),
                      )
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