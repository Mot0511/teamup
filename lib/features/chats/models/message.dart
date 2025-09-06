import 'dart:io';
import 'package:flutter/material.dart';
import 'package:teamup/features/user/models/models.dart';

class Message {
  final int id;
  final int chatId;
  final User user;
  String text;
  final int? repliedMesssageID;
  final ImageProvider? attachment;
  DateTime time;

  Message({
    required this.id, 
    required this.chatId, 
    required this.user, 
    required this.text, 
    this.repliedMesssageID,
    this.attachment,
    required this.time
  });

  factory Message.fromJSON(Map data) {
    return Message(
      id: data['id'],
      chatId: data['chat'],
      user: User.fromJSON(data['sender']),
      text: data['text'],
      repliedMesssageID: data['repliedMessage'],
      attachment: data['attachment'],
      time: DateTime.parse(data['created_at']).toLocal(),
    );
  }

  Map toJSON() {
    return {
      'id': id,
      'chat': chatId,
      'sender': user.uid,
      'text': text,
      'repliedMessage': repliedMesssageID,
      'attachment': attachment != null ? id : null
    };
  }
}