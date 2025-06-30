import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/user/models/models.dart';

class Team extends Chat {
  String name;
  
  Team({required super.id, required super.users, required this.name});

  factory Team.fromJSON(Map data) {
    return Team(
      id: data['id'],
      users: data['users'].map((user) => User.fromJSON(user)).toList(),
      name: data['name']
    );
  }

  Map toJSON() {
    return {
      'id': id,
      'name': name,
      'is_team': true,
    };
  }
}