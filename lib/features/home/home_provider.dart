import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/models/game.dart';

class HomeProvider extends ChangeNotifier {
  final searchRepository = GetIt.I<SearchRepository>();

  List<Game>? games;

  void loadGames() async {
    games = await searchRepository.getGames();
    notifyListeners();
  }
}