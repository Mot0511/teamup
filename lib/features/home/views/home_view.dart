
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:teamup/features/analytics/analytics.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/home/widgets/filters_button_widget.dart';
import 'package:teamup/features/teams/widgets/public_team_widget.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/widgets/darkblur_button_widget.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {

  final supabase = GetIt.I<SupabaseClient>();
  final userBloc = GetIt.I<UserBloc>();
  final teamsBloc = GetIt.I<TeamsBloc>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  late AnimationController filtersAnimationController;
  late Animation<double> filtersAnimation;
  late Animatable filtersTweenWidth;
  late Animatable filtersTweenHeight;
  late Animatable addButtonTweenPosition;

  UpdateInfo? updateInfo;
  String? appVersion;

  List<Team>? publicTeams;

  @override
  void initState() {
    super.initState();

    checkVersion();
    loadPublicTeams();
    setupAnimations();

    loadPublicTeams();
    userBloc.stream.listen((state) {
      loadPublicTeams();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => checkVersion());
  }

  void setupAnimations() {
    filtersAnimationController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    filtersAnimationController.addListener(() => setState(() {}));
    filtersAnimation = CurvedAnimation(parent: filtersAnimationController, curve: Curves.easeInOutQuad);

    filtersTweenWidth = Tween<double>(begin: 0.83, end: 1.0);
    filtersTweenHeight = Tween<double>(begin: 60, end: 410);
    addButtonTweenPosition = Tween<double>(begin: 0, end: 60);
  }

  Future<void> loadPublicTeams({Completer? completer}) async {
    if (teamsBloc.state is TeamsStateInitial || completer != null) {
      teamsBloc.add(LoadPublicTeams(completer: completer));
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
                body: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final completer = Completer();
                      await loadPublicTeams(completer: completer);
                      return completer.future;
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(10),
                      child: Stack(
                        alignment: AlignmentDirectional.bottomStart,
                        children: [
                          BlocBuilder(
                            bloc: teamsBloc,
                            builder: (context, state) {
                              if (state is TeamsStateLoaded) {
                                return ListView(
                                  padding: EdgeInsets.only(bottom: 70),
                                  children: state.publicTeams.map((team) => 
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 10),
                                      child: PublicTeamWidget(team: team),
                                    )
                                  ).toList()
                                );
                              } else if (state is TeamsStateError) {
                                return Center(
                                  child: Column(
                                    children: [
                                      Text('Произошла ошибка при загрузке команд', style: theme.textTheme.bodyMedium),
                                      Text(state.e.toString(), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                    ],
                                  )
                                );
                              }
                              return Column(
                                children: List.generate(3, (i) => 
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: ShimmerWidget(height: 100)
                                  )
                                ),
                              );
                            }
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 5, left: 5),
                                child: FiltersButtonWidget(
                                  width: constraints.maxWidth * filtersTweenWidth.evaluate(filtersAnimation),
                                  height: filtersTweenHeight.evaluate(filtersAnimation) - 60.0,
                                  filtersAnimationController: filtersAnimationController,
                                )
                              );
                            },
                          ),
                          Positioned(
                            bottom: 5,
                            right: -addButtonTweenPosition.evaluate(filtersAnimation)+3,
                            child: DarkButtonWidget(
                              width: 60,
                              height: 60,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateTeamView())), 
                              child: Icon(Icons.add, size: 30)
                            )
                          )
                      ],
                      ),
                    )
                  )
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