import 'package:flutter/material.dart';
import 'package:teamup/features/user/user.dart';

class Message {
  final int id;
  final int chatId;
  final User user;
  String text;
  final int? repliedMesssageID;
  ImageProvider? attachment;
  DateTime time;
  bool isReaded;

  Message({
    required this.id,
    required this.chatId,
    required this.user,
    required this.text,
    this.repliedMesssageID,
    this.attachment,
    required this.time,
    required this.isReaded,
  });

  factory Message.fromJSON(
    Map data, {
    required User sender,
    bool isReaded = false,
  }) {
    final dynamic chat = data['chat'];
    final int chatId = chat is Map
        ? ((chat['id'] as num?)?.toInt() ?? 0)
        : int.tryParse('${data['chat']}') ?? 0;

    final dynamic attachment = data['attachment'];
    return Message(
      id: (data['id'] as num).toInt(),
      chatId: chatId,
      user: sender,
      text: '${data['text'] ?? ''}',
      repliedMesssageID: data['repliedMessage'] != null
          ? int.tryParse('${data['repliedMessage']}')
          : null,
      attachment: attachment != null
          ? NetworkImage('$attachment')
          : null,
      time: DateTime.tryParse('${data['sendedAt']}')?.toLocal() ?? DateTime.now(),
      isReaded: isReaded,
    );
  }


  Map toJSON() {
    return {
      'id': id,
      'text': text,
      'localDateTime': DateTime.now().toIso8601String(),
      'zoneId': DateTime.now().timeZoneName,
    };
  }

}