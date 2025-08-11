import 'package:teamup/models/game.dart';

class SearchParams {
  final int gameID;
  final int age;
  final String gender;
  final int teamSize;

  SearchParams({required this.gameID, required this.age, required this.gender, required this.teamSize});
}