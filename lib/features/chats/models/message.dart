import 'package:teamup/features/chats/enums.dart';
import 'package:teamup/features/user/models/models.dart';

class Message {
  final int id;
  final int chatId;
  final ChatType chatType;
  final User user;
  final String text;
  final DateTime time;

  Message({required this.id, required this.chatId, required this.chatType, required this.user, required this.text, required this.time});

  factory Message.fromJSON(Map data) {
    return Message(
      id: data['id'],
      chatId: data['chat'],
      chatType: data['chat_type'] == 'chat' ? ChatType.chat : ChatType.team,
      user: User.fromJSON(data['sender']),
      text: data['text'],
      time: DateTime.parse(data['created_at']),
    );
  }
}