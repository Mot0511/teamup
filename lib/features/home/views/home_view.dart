
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:teamup/features/analytics/analytics.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/teams/views/public_teams_view.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/widgets/shimmer_widget.dart';
import 'package:audioplayers/audioplayers.dart';

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

  Game? currentGame;
  String currentTeamSize = '2';
  String currentGender = 'male';

  List<User> pendingUsers = [];

  UpdateInfo? updateInfo;
  String? appVersion;

  @override
  void initState() {
    super.initState();

    checkVersion();

    currentTeamSize = prefs.getString('currentTeamSize') ?? '2';
    currentGender = prefs.getString('currentGender') ?? 'male';

    loadGames();

    searchRepository.onTeamFormed = (Team team) async {
      if (!kIsWeb && Platform.isWindows && !notificationsService.isOnline) notificationsService.showNotification(DateTime.now().millisecondsSinceEpoch.toString(), 'Команда сформирована', '');
      searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user));
      await AudioPlayer().play(AssetSource('audio/team_formed.mp3'));
      analyticsRepository.logEvent('finish_searching', properties: getParams()!.toJSON());
      Navigator.push(context, MaterialPageRoute(builder: (_) => TeamView(team: team)));
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

    WidgetsBinding.instance.addPostFrameCallback((_) => checkVersion());
  }

  Future<void> loadGames() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.games == null) {
      await homeProvider.loadGames();
    }
    final currentGameID = prefs.getString('currentGame') ?? '206';
    currentGame = homeProvider.games!.firstWhere((game) => game.id.toString() == currentGameID);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> checkVersion() async {
    final platformInfo = await PackageInfo.fromPlatform();
    appVersion = platformInfo.version;
    final res = await supabase.functions.invoke(
      'check-version',
    );

    updateInfo = UpdateInfo.fromJSON(res.data);
    if (mounted) {
      setState(() {});
    }
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

  SearchParams? getParams() {
    if (currentGame != null) {
      return SearchParams(
        gameID: currentGame!.id,
        age: (userBloc.state as UserStateLoaded).user.age, 
        gender: currentGender, 
        teamSize: int.parse(currentTeamSize)
      );
    }
    return null;
  }

  Future<void> onStartSearching() async {
    final params = getParams();
    if (params != null) {
      await animationController.reverse();
      searchBloc.add(StartSearching(
        user: (userBloc.state as UserStateLoaded).user,
        params: params,
      ));
      await animationController.forward();
    }
  }

  Future<void> onStopSearching() async {
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
                  bottom: updateInfo != null && updateInfo?.currentVersion != appVersion ? UpdateMessageWidget(updateInfo: updateInfo!) : null,
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
                      flex: 6, 
                      child: Center(
                        child: BlocBuilder(
                          bloc: searchBloc,
                          builder: (context, state) {
                            if (state is SearchStateInitial) {
                              return ShimmerWidget(
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
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SearchBtn(
                                  onStartSearching: onStartSearching,
                                  onStopSearching: onStopSearching,
                                  state: state as SearchState
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicTeamsView())),
                                  child: Text('Публичные команды', style: theme.textTheme.labelMedium)
                                )
                              ],
                            );
                          }
                        )
                      )
                    ),
                      Expanded(
                        flex: 7,
                        child: currentGame != null
                          ? Padding(
                              padding: EdgeInsetsGeometry.symmetric(horizontal: 18),
                              child: InfoWidget(
                                currentGame: currentGame!,
                                onSetGame: (Game game) async {
                                  await prefs.setString('currentGame', game.id.toString());
                                  setState(() => currentGame = game);
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
                              child: ShimmerWidget(width: double.infinity, height: double.infinity),
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
