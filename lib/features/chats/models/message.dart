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
}