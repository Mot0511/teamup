import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/bloc/search_bloc.dart';
import 'package:teamup/features/home/bloc/search_events.dart';
import 'package:teamup/features/home/bloc/search_states.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/user/bloc/user_states.dart';

class SearchBtn extends StatefulWidget {
  SearchBtn({
    super.key,
    required this.onStartSearching,
    required this.onStopSearching,
    required this.state
  });
  final Function onStartSearching;
  final Function onStopSearching;
  final SearchState state;

  @override
  State<SearchBtn> createState() => _SearchBtnState();
}

class _SearchBtnState extends State<SearchBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation colorAnimation;

  final searchBloc = GetIt.I<SearchBloc>();

  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );

    searchBloc.stream.listen((state) {
      if (searchBloc.state is SearchStateSearching) {
        animationController.repeat(reverse: true);
      } else {
        animationController.animateBack(1);
      }
    });

    colorAnimation = ColorTween(begin: const Color.fromARGB(255, 0, 88, 46), end: const Color(0xff004323)).animate(animationController);
  }

  void searchHandler(state) {
    if (state is SearchStateSearching) {
      animationController.stop();
      widget.onStopSearching();
    } else {
      animationController.repeat(reverse: true);
      widget.onStartSearching();
    }
  }

  void dispose() {
    animationController.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, color) {
        return SizedBox(
          width: 180,
          height: 180,
          child: Ink(
            decoration: BoxDecoration(
              color: colorAnimation.value,
              border: Border.all(color: theme.primaryColor, width: 5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: InkWell(
              onTap: () => searchHandler(widget.state),
              customBorder: CircleBorder(),
              splashColor: theme.primaryColor,
              child: Icon(
                Icons.search,
                color: Colors.white, 
                size: 100
              ),
            ),
          ),
        );
      }
    );
  }
}
