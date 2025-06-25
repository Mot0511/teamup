import 'package:teamup/features/chats/models/message.dart';
import 'package:teamup/features/user/models/models.dart';

class Chat {
  final int id;
  final User user1;
  final User user2;
  final Message? lastMessage;

  Chat({required this.id, required this.user1, required this.user2, this.lastMessage});

  factory Chat.fromJSON(Map data) {
    return Chat(
      id: data['id'],
      user1: User.fromJSON(data['user1']),
      user2: User.fromJSON(data['user2']),
      lastMessage: data['lastMessage']
    );
  }

  Map toJSON() {
    return {
      'id': id,
      'user1': user1.toJSON(),
      'user2': user2.toJSON(),
    };
  }
}