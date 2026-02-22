import 'package:teamup/features/user/user.dart';

class Chat {
  final int id;
  List users;

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