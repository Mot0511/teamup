import 'package:teamup/models/game.dart';

class User {
  final String uid;
  final String email;
  String username;
  String? description;
  String gender;
  int age;
  Game? favouriteGame;

  User({
    required this.uid,
    required this.username,
    this.description,
    required this.email,
    required this.gender,
    required this.age,
    this.favouriteGame,
  });

  factory User.fromJSON(Map data) {
    final dynamic game = data['favouriteGame'];
    return User(
      uid: '${data['uid']}',
      username: '${data['username']}',
      description: data['description']?.toString(),
      email: '${data['email'] ?? ''}',
      gender: '${data['gender'] ?? ''}',
      age: data['age'] is num
          ? (data['age'] as num).toInt()
          : int.tryParse('${data['age']}') ?? 0,
      favouriteGame: game != null
          ? Game.fromJSON(game)
          : null,
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'username': username,
      'description': description,
      'gender': gender,
      'age': age,
      'game': favouriteGame?.id,
    };
  }
}