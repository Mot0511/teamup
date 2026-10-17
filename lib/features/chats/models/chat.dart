import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';

class Chat {
  final int id;
  List<User> users;
  String? lastMessage;
  Game? game;

  Chat({
    required this.id,
    required this.users,
    this.lastMessage,
    this.game,
  });

  factory Chat.fromJSON(Map data, {List<User>? users}) {
    final dynamic game = data['game'];
    return Chat(
      id: (data['id'] as num).toInt(),
      users: users ?? [],
      lastMessage: data['lastMessage']?.toString(),
      game: game != null ? Game.fromId(int.tryParse('$game') ?? 0) : null,
    );
  }
}