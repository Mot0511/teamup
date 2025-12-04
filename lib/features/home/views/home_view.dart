
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:teamup/features/analytics/views/analytics_view.dart';
import 'package:teamup/features/home/bloc/search_bloc.dart';
import 'package:teamup/features/home/bloc/search_events.dart';
import 'package:teamup/features/home/bloc/search_states.dart';
import 'package:teamup/features/home/home_provider.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/home/views/search_view.dart';
import 'package:teamup/features/home/widgets/drop_down_widget.dart';
import 'package:teamup/features/home/widgets/info_widget.dart';
import 'package:teamup/features/home/widgets/widgets.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/signaling_service2.dart';
import 'package:teamup/features/teams/views/team_view.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/features/analytics/repositories/analytics_repository.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {

  late final AnimationController animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: 1.0,
  );

  final userBloc = GetIt.I<UserBloc>();
  final searchBloc = GetIt.I<SearchBloc>();
  final supabase = GetIt.I<SupabaseClient>();
  final searchRepository = GetIt.I<SearchRepository>();
  final analyticsRepository = GetIt.I<AnalyticsRepository>();
  final notificationsService = GetIt.I<NotificationsService>();
  final prefs = GetIt.I<SharedPreferences>();

  String currentGame = '106';
  String currentTeamSize = '2';
  String currentGender = 'male';

  List<User> pendingUsers = [];

  @override
  void initState() {
    super.initState();
    
    currentGame = prefs.getString('currentGame') ?? '106';
    currentTeamSize = prefs.getString('currentTeamSize') ?? '2';
    currentGender = prefs.getString('currentGender') ?? 'male';
    setState(() {});

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.games == null) {
      homeProvider.loadGames();
    }

    searchRepository.onTeamFormed = (Team team) {
      analyticsRepository.logEvent('finish_searching', properties: getParams().toJSON());
      if (Platform.isWindows && !notificationsService.isOnline) notificationsService.showNotification(DateTime.now().millisecondsSinceEpoch.toString(), 'Команда сформирована', '');
      Navigator.push(context, MaterialPageRoute(builder: (_) => TeamView(team: team)));
      searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user));
    };
    searchRepository.onTeamFound = (List<User> users) {
      pendingUsers = users;
      setState(() {});
    };
    searchRepository.onNewPendingUser = (User user) {
      pendingUsers.add(user);
      setState(() {});
    };
    searchRepository.onRemovePendingUser = (String userID) {
      pendingUsers = pendingUsers.where((pendingUser) => pendingUser.uid != userID).toList();
    };

    checkSearching();
    userBloc.stream.listen((state) {
      checkSearching();
    });
  }

  Future<void> checkSearching() async {
    if (userBloc.state is UserStateLoaded) {
      final int? pendingTeamID = await searchRepository.getPendingTeamID((userBloc.state as UserStateLoaded).user.uid);
      if (pendingTeamID != null) {
        searchBloc.add(RestoreSearching(pendingTeamID: pendingTeamID));
        return;
      }
      searchBloc.add(GetReady());
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

  void onStartSearching() async {
    await animationController.reverse();
    searchBloc.add(StartSearching(
      user: (userBloc.state as UserStateLoaded).user,
      params: getParams(),
    ));
    await animationController.forward();
  }

  void onStopSearching() async {
    await animationController.reverse();
    searchBloc.add(StopSearching(
      user: (userBloc.state as UserStateLoaded).user,
    ));
    pendingUsers.clear();
    setState(() {});
    await animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        return BlocBuilder(
          bloc: userBloc,
          builder: (context, state) {
            if (state is UserStateLoaded) {
              return Scaffold(
                appBar: AppBar(
                  title: Text('Teamup', style: theme.textTheme.headlineMedium),
                  centerTitle: true,
                  actions: [
                    if (state.user.uid == 'ea28f58d-2679-4c86-b0fb-2506947b0794')
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AnalyticsView()),
                      ),
                      icon: Icon(Icons.analytics_outlined),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AllUsersView()),
                      ),
                      icon: Icon(Icons.search),
                    ),
                  ],
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4, 
                      child: Center(
                        child: BlocBuilder(
                          bloc: searchBloc,
                          builder: (context, state) {
                            if (state is SearchStateInitial) {
                              return SihmmerWidget(
                                width: 180,
                                height: 180,
                                radius: 100,
                              ); 
                            } else if (state is SearchStateError) {
                              return Column(
                                children: [
                                  Text('Ошибка при инициализации поиска', style: theme.textTheme.titleMedium),
                                  Text(state.e.toString(), style: theme.textTheme.titleMedium)
                                ],
                              );
                            }
                            return SearchBtn(
                              onStartSearching: onStartSearching,
                              onStopSearching: onStopSearching,
                              state: state as SearchState
                            );
                          }
                        )
                      )
                    ),
                      Expanded(
                        flex: 4,
                        child: homeProvider.games != null
                          ? Padding(
                              padding: EdgeInsetsGeometry.symmetric(horizontal: 18),
                              child: InfoWidget(
                                currentGame: currentGame, 
                                games: homeProvider.games!, 
                                onSetGame: (value) async {
                                  await prefs.setString('currentGame', value);
                                  setState(() => currentGame = value);
                                },
                                currentGender: currentGender, 
                                onSetGender: (value) async {
                                  await prefs.setString('currentGender', value);
                                  setState(() => currentGender = value);
                                },
                                currentTeamSize: currentTeamSize, 
                                onSetTeamSize: (value) async {
                                  await prefs.setString('currentTeamSize', value);
                                  setState(() => currentTeamSize = value);
                                },
                                animationController: animationController,
                                pendingUsers: pendingUsers
                              )
                            )
                          : Padding(
                              padding: EdgeInsets.all(16),
                              child: SihmmerWidget(width: double.infinity, height: double.infinity),
                            )
                      )
                  ],
                )
              );
            } else if (state is UserStateLoaded) {
              return Center(child: Text('Ошибка при загрузке данных пользователя'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        );
      }
    );
  }
}
