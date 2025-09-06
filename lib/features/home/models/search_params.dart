import 'package:teamup/models/game.dart';

class SearchParams {
  final int gameID;
  final int age;
  final String gender;
  final int teamSize;

  SearchParams({required this.gameID, required this.age, required this.gender, required this.teamSize});

  Map toJSON() {
    return {
      'game': gameID,
      'min_age': age - 1,
      'max_age': age + 1,
      'gender': gender,
      'team_size': teamSize
    };
  }
}