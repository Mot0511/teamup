import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';

class Team extends Chat {
  String name;
  bool isPublic;
  Game? game;

  Team({
    required super.id,
    required super.users,
    required this.name,
    required this.isPublic,
    this.game,
  });

  factory Team.fromJSON(Map data, {List<User>? users}) {
    final dynamic game = data['game'];
    return Team(
      id: (data['id'] as num).toInt(),
      users: users ?? const [],
      name: '${data['name'] ?? ''}',
      isPublic: data['public'] ?? false,
      game: game != null ? Game.fromJSON(game) : null,
    );
  }
}