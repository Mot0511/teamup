import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/models/game.dart';

class HomeProvider extends ChangeNotifier {
  final searchRepository = GetIt.I<SearchRepository>();

  List<Game>? games;

  Future<void> loadGames() async {
    games = await searchRepository.getGames();
    notifyListeners();
  }
}