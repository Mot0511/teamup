import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/home/bloc/search_bloc.dart';
import 'package:teamup/features/home/bloc/search_events.dart';
import 'package:teamup/features/home/bloc/search_states.dart';
import 'package:teamup/features/home/home_provider.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/home/views/all_users_view.dart';
import 'package:teamup/features/home/widgets/drop_down_widget.dart';
import 'package:teamup/features/home/widgets/widgets.dart';
import 'package:teamup/features/teams/signaling_service.dart';
import 'package:teamup/features/teams/views/team_view.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/models/game.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final userBloc = GetIt.I<UserBloc>();
  final searchBloc = GetIt.I<SearchBloc>();
  final supabase = GetIt.I<SupabaseClient>();
  final searchRepository = GetIt.I<SearchRepository>();

  String currentGame = '1';
  String currentTeamSize = '2';
  String currentGender = 'male';

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentSession!.user;
    userBloc.add(LoadUser(uid: user.id));

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.games == null) {
      homeProvider.loadGames();
    }
  }

  SearchParams getParams() {
    return SearchParams(
      gameID: int.parse(currentGame), 
      age: (userBloc.state as UserStateLoaded).user.age, 
      gender: currentGender, 
      teamSize: int.parse(currentTeamSize)
    );
  }

  void onStartSearching() {
    searchBloc.add(StartSearching(
      user: (userBloc.state as UserStateLoaded).user,
      params: getParams(),
      onTeamFormed: (team) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TeamView(team: team)));
        searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user, params: getParams()));
      }
    ));
  }

  void onStopSearching() {
    searchBloc.add(StopSearching(
      user: (userBloc.state as UserStateLoaded).user,
      params: getParams(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Teamup', style: theme.textTheme.headlineMedium),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AllUsersView()),
                ),
                icon: Icon(Icons.people_alt),
              ),
            ],
          ),
          body: BlocBuilder(
            bloc: userBloc,
            builder: (context, state) {
              if (state is UserStateLoaded) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4, 
                      child: Center(
                        child: SearchBtn(
                          onStartSearching: onStartSearching,
                          onStopSearching: onStopSearching,
                        )
                      )
                    ),
                    if (homeProvider.games != null)
                      Expanded(
                        flex: 4,
                        child: BlocBuilder(
                          bloc: searchBloc,
                          builder: (context, state) {
                            if (state is SearchStateInitial) {
                              return Padding(
                                padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        "Фильтры поиска",
                                        style: theme.textTheme.headlineMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Text("Игра", style: theme.textTheme.labelMedium),
                                    DropdowmWidget(
                                      items: homeProvider.games!
                                          .map(
                                            (game) => DropdownItem(
                                              text: game.name,
                                              value: game.id.toString(),
                                            ),
                                          )
                                          .toList(),
                                      value: currentGame,
                                      onChange: (value) =>
                                          setState(() => currentGame = (value as String)),
                                    ),
                                    Text(
                                      "Кол-во игроков в команде",
                                      style: theme.textTheme.labelMedium,
                                    ),
                                    DropdowmWidget(
                                      items: [
                                        DropdownItem(text: '2', value: '2'),
                                        DropdownItem(text: '3', value: '3'),
                                        DropdownItem(text: '4', value: '4'),
                                        DropdownItem(text: '5', value: '5'),
                                        DropdownItem(text: '6', value: '6'),
                                        DropdownItem(text: '7', value: '7'),
                                        DropdownItem(text: '8', value: '8'),
                                        DropdownItem(text: '9', value: '9'),
                                        DropdownItem(text: '10', value: '10'),
                                      ],
                                      value: currentTeamSize,
                                      onChange: (value) =>
                                          setState(() => currentTeamSize = (value as String)),
                                    ),
                                    Text("Пол", style: theme.textTheme.labelMedium),
                                    DropdowmWidget(
                                      items: [
                                        DropdownItem(text: "Не важно", value: "null"),
                                        DropdownItem(text: "Мужской", value: "male"),
                                        DropdownItem(text: "Женский", value: "female"),
                                      ],
                                      value: currentGender,
                                      onChange: (value) =>
                                          setState(() => currentGender = (value as String)),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Center(child: Text('Идет поиск...', style: theme.textTheme.titleLarge));
                            }
                          }
                        )
                      ),
                  ],
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }
          )
        );
      }
    );
  }
}
