import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/bloc/search_bloc.dart';
import 'package:teamup/features/home/bloc/search_states.dart';
import 'package:teamup/features/home/widgets/drop_down_widget.dart';
import 'package:teamup/features/home/widgets/filters_widget.dart';
import 'package:teamup/features/home/widgets/pending_team_state_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class InfoWidget extends StatefulWidget {
  const InfoWidget({
    super.key, 
    required this.currentGame,
    required this.games,
    required this.onSetGame,

    required this.currentGender,
    required this.onSetGender,

    required this.currentTeamSize,
    required this.onSetTeamSize,

    required this.animationController,

    required this.pendingUsers
  });
  final String currentGame;
  final List<Game> games;
  final Function onSetGame;

  final String currentGender;
  final Function onSetGender;

  final String currentTeamSize;
  final Function onSetTeamSize;

  final AnimationController animationController;

  final List<User> pendingUsers;


  @override
  State<InfoWidget> createState() => _InfoWidgetState();
}

class _InfoWidgetState extends State<InfoWidget> {
  
  final searchBloc = GetIt.I<SearchBloc>();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder(
      bloc: searchBloc,
      builder: (context, state) {
        final opacity = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: widget.animationController,
            curve: Curves.easeInOutCubic,
          ),
        );
        if (state is SearchStateReady) {
          return FadeTransition(
            opacity: opacity,
            child: FiltersWidget(
              currentGame: widget.currentGame, 
              games: widget.games, 
              onSetGame: (value) => widget.onSetGame(value),
              currentGender: widget.currentGender, 
              onSetGender: (value) => widget.onSetGender(value),
              currentTeamSize: widget.currentTeamSize, 
              onSetTeamSize: (value) => widget.onSetTeamSize(value),
            ),
          );
        } else if (state is SearchStateSearching) {
          return FadeTransition(
            opacity: opacity,
            child: PendingTeamStateWidget(
              currentTeamSize: widget.currentTeamSize,
              pendingUsers: widget.pendingUsers
            ),
          );
        } else {
          return SihmmerWidget(height: 100);
        }
      }
    );
  }
}