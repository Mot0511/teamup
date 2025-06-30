import 'package:teamup/features/chats/models/models.dart';
import 'package:teamup/features/user/models/models.dart';

class Chat {
  final int id;
  List<User> users;

  Chat({required this.id, required this.users});

  factory Chat.fromJSON(Map data) {
    return Chat(
      id: data['id'],
      users: data['users'].map((user) => User.fromJSON(user)).toList(),
    );
  }

  Map toJSON() {
    return {
      'id': id,
      'is_team': false,
      'name': null,
    };
  }
}