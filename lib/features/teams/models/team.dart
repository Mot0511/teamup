import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';

class Team extends Chat {
  String name;
  bool isPublic;
  Game? game;
  
  Team({required super.id, required super.users, required this.name, required this.isPublic, this.game});

  factory Team.fromJSON(Map data) {
    return Team(
      id: data['id'],
      users: data['users'].map((data) => User.fromJSON(data)).toList(),
      name: data['name'],
      isPublic: data['is_public'],
      game: data['game'] != null ? Game.fromJSON(data['game']) : null
    );
  }

  @override
  Map toJSON() {
    return {
      'id': id,
      'name': name,
      'is_team': true,
      'is_public': isPublic,
      'game': game?.id
    };
  }

  Map toJSONWithMembers() {
    final data = toJSON();
    data['users'] = users.map((user) => user.toJSON()).toList();
    return data;
  }
}