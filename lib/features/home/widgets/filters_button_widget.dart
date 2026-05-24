import 'dart:io';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teamup/features/analytics/analytics.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/models/user.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class FiltersButtonWidget extends StatefulWidget {
  const FiltersButtonWidget({
    super.key, 
    required this.width,
    required this.height,
    required this.filtersAnimationController,
  });
  final double width;
  final double height;
  final AnimationController filtersAnimationController;

  @override
  State<FiltersButtonWidget> createState() => _FiltersButtonWidgetState();
}

class _FiltersButtonWidgetState extends State<FiltersButtonWidget> with SingleTickerProviderStateMixin  {
  
  final prefs = GetIt.I<SharedPreferences>();
  final searchRepository = GetIt.I<SearchRepository>();
  final notificationsService = GetIt.I<NotificationsService>();
  final analyticsRepository = GetIt.I<AnalyticsRepository>();
  final userBloc = GetIt.I<UserBloc>();
  final searchBloc = GetIt.I<SearchBloc>();

  late AnimationController searchAnimationController;
  Game? currentGame;
  String currentTeamSize = '2';
  String currentGender = 'male';

  List<User> pendingUsers = [];

  void initState() {
    searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 1.0,
    );

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
    
    currentTeamSize = prefs.getString('currentTeamSize') ?? '2';
    currentGender = prefs.getString('currentGender') ?? 'male';

    checkSearching();
    userBloc.stream.listen((state) {
      checkSearching();
    });

    loadGames();
  }

  Future<void> onStartSearching() async {
    final params = getParams();
    if (params != null) {

      await searchAnimationController.reverse();
      searchBloc.add(StartSearching(
        user: (userBloc.state as UserStateLoaded).user,
        params: params,
      ));
      await searchAnimationController.forward();
    }
  }

  Future<void> onStopSearching() async {
    await searchAnimationController.reverse();
    searchBloc.add(StopSearching(
      user: (userBloc.state as UserStateLoaded).user,
    ));
    pendingUsers.clear();
    setState(() {});
    await searchAnimationController.forward();
  }

  void toggleFilters() {
    if (widget.filtersAnimationController.status == AnimationStatus.completed) {
      widget.filtersAnimationController.reverse();
    } else {
      widget.filtersAnimationController.forward();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(36, 35, 35, 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.hardEdge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 60,
                child: GestureDetector(
                  onTap: toggleFilters,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    child: BlocBuilder(
                      bloc: searchBloc,
                      builder: (context, state) {
                        if (state is SearchStateReady) {
                          return Text(
                            'Быстрый поиск',
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          );
                        } else if (state is SearchStateSearching) {
                          return Text(
                            'Идет поиск...',
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          );
                        }
                        return Text(
                          'Загрузка...',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                        );
                      }
                    )
                  )
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: widget.height,
                child: OverflowBox(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: currentGame != null
                      ? InfoWidget(
                        onStartSearching: onStartSearching,
                        onStopSearching: onStopSearching,
                        pendingUsers: pendingUsers,
                        currentGame: currentGame!, 
                        onSetGame: (Game game) => setState(() => currentGame = game),
                        currentGender: currentGender, 
                        onSetGender: (String gender) => setState(() => currentGender = gender), 
                        currentTeamSize: currentTeamSize, 
                        onSetTeamSize: (String teamSize) => setState(() => currentTeamSize = teamSize),
                        animationController: searchAnimationController,
                      )
                      : ShimmerWidget()
                  )
                ),
              )
            ],
          ),
        )
      );
  }
}