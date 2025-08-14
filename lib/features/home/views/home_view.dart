import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
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
import 'package:teamup/features/teams/signaling_service.dart';
import 'package:teamup/features/teams/views/team_view.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';
import 'package:teamup/models/game.dart';

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

  String currentGame = '1';
  String currentTeamSize = '2';
  String currentGender = 'male';

  List<User> pendingUsers = [];

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentSession!.user;
    userBloc.add(LoadUser(uid: user.id));

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.games == null) {
      homeProvider.loadGames();
    }

    searchRepository.onTeamFormed = (Team team) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TeamView(team: team)));
      searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user, params: getParams()));
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
      params: getParams(),
    ));
    pendingUsers.clear();
    setState(() {});
    await animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
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
                icon: Icon(Icons.search),
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
                        child: Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 18),
                          child: InfoWidget(
                            currentGame: currentGame, 
                            games: homeProvider.games!, 
                            onSetGame: (value) => setState(() {currentGame = value;}), 
                            currentGender: currentGender, 
                            onSetGender: (value) => setState(() {currentGender = value;}), 
                            currentTeamSize: currentTeamSize, 
                            onSetTeamSize: (value) => setState(() {currentTeamSize = value;}), 
                            animationController: animationController,

                            pendingUsers: pendingUsers
                          )
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
