import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/bloc/search_bloc.dart';
import 'package:teamup/features/home/bloc/search_events.dart';
import 'package:teamup/features/home/bloc/search_states.dart';
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/teams/views/team_view3.dart';
import 'package:teamup/features/user/bloc/user_states.dart';

class SearchBtn extends StatefulWidget {
  SearchBtn({
    super.key,
    required this.onStartSearching,
    required this.onStopSearching
  });
  final Function onStartSearching;
  final Function onStopSearching;

  @override
  State<SearchBtn> createState() => _SearchBtnState();
}

class _SearchBtnState extends State<SearchBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: 1.0,
  );

  final searchBloc = GetIt.I<SearchBloc>();

  void searchHandler(state) {
    if (state is SearchStateSearching) {
      widget.onStopSearching();
      controller.forward();
    } else {
      widget.onStartSearching();
      controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SearchBloc, SearchState>(
      bloc: searchBloc,
      builder: (context, state) {
        return AnimatedContainer(
          width: state is SearchStateSearching ? 150 : 180,
          height: state is SearchStateSearching ? 150 : 180,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xff004323),
              border: Border.all(color: theme.primaryColor, width: 5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: InkWell(
              onTap: () => searchHandler(state),
              customBorder: CircleBorder(),
              splashColor: theme.primaryColor,
              child: ScaleTransition(
                scale: Tween(begin: 0.7, end: 1.0).animate(
                  CurvedAnimation(
                    parent: controller,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
                child: Icon(Icons.search, color: Colors.white, size: 100),
              ),
            ),
          ),
        );
      },
    );
  }
}
