import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class ChooseGameView extends StatefulWidget {
  const ChooseGameView({super.key});

  @override
  State<ChooseGameView> createState() => _ChooseGameViewState();
}

class _ChooseGameViewState extends State<ChooseGameView> {

  List<Game>? games;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = context.read<HomeProvider>();
      if (homeProvider.games != null) {
        loadGames(homeProvider);
      }
      homeProvider.addListener(() => loadGames(homeProvider));
    });
  }

  void loadGames(HomeProvider homeProvider) {
    games = homeProvider.games;
    if (mounted) {
      setState(() {});
    }
  }

  void onSearch(String title) {
    final homeProvider = context.read<HomeProvider>();
    if (title == '') {
      loadGames(homeProvider);
    }
    games = homeProvider.games!.where((game) => game.name.contains(title)).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Выбор игры'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: games != null
          ? Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
                  border: UnderlineInputBorder(),
                ),
                style: theme.textTheme.labelMedium,
                maxLines: 1,
                onChanged: onSearch,
              ),
              Expanded(
                child: ListView(
                  children: games!.map((game) => GameWidget(game: game, onTap: () => Navigator.pop(context, game))).toList()
                )
              )
            ],
          )
        : Column(
          children: List.generate(5, (_) => Padding(
            padding: EdgeInsetsGeometry.only(bottom: 10),
            child: ShimmerWidget(height: 80),
          )),
        )
      )
    );
  }
}