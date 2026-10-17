import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/services/realtime_service.dart';
import 'package:teamup/features/chats/utils/get_user_from_members.dart';
import 'package:timezone/timezone.dart' as tz;

class ChatsRepository {
  final dio = GetIt.I<Dio>();
  final realtime = GetIt.I<RealtimeService>();
  final Map<int, ImageProvider> attachmentProviders = {};

  Future<List<Chat>> getChats(String uid) async {
    final res = await dio.get('/chats/');
    final data = (res.data as List).cast<Map>().toList();

    final List<Chat> chats = [];
    for (Map row in data) {
      if (row['team'] == true) continue;
      final chatId = (row['id'] as num).toInt();
      final users = await getChatUsers(chatId);

      String? lastMessage;
      try {
        final message = await dio.get('/messages/$chatId/last');
        final text = '${message.data['text'] ?? ''}';
        lastMessage = text.isNotEmpty ? text : 'Картинка';
      } on DioException catch (_) {
        lastMessage = null;
      }

      chats.add(Chat(
        id: chatId,
        users: users,
        lastMessage: lastMessage,
      ));
    }
    return chats;
  }

  /// Создаёт личный чат с партнёром и возвращает созданный чат (id от сервера).
  Future<Chat> addChat(Chat chat, String uid) async {
    final companion = chat.users.firstWhere((user) => user.uid != uid);
    final res = await dio.post('/chats/', queryParameters: {'other': companion.uid});
    final users = await getChatUsers((res.data['id'] as num).toInt());
    return Chat.fromJSON(res.data, users: users);
  }

  Future<List<User>> getChatUsers(int chatId) async {
    final res = await dio.get('/chats/$chatId/users');
    return (res.data as List).cast<Map>().map((user) => User.fromJSON(user)).toList();
  }

  Future<Chat> getChat(int id) async {
    final res = await dio.get('/chats/$id');
    final users = await getChatUsers(id);
    return Chat.fromJSON(res.data, users: users);
  }

  /// Возвращает пользователя-собеседника (не текущего) в личном чате.
  Future<User> getMessageSender(int chatID, String currentUid) async {
    final users = await getChatUsers(chatID);
    final result = users.where((user) => user.uid != currentUid).toList();
    return result.isNotEmpty ? result.first : users.first;
  }

  Future<void> removeChat(int chatID) async {
    await dio.delete('/chats/$chatID');
  }

  Future<List<Message>> getMessages(int chatID) async {
    final res = await dio.get('/messages/$chatID');
    final data = (res.data as List).cast<Map>().toList();
    final users = await getChatUsers(chatID);
    List<int> readed = [];
    try {
      readed = await getReadedMessages(chatID);
    } on DioException catch (_) {}

    final List<Message> messages = [];
    for (Map message in data) {
      if (message['attachment'] != null) {
        try {
          message['attachment'] = await getAttachmentUrl((message['id'] as num).toInt());
        } on DioException catch (_) {
          message['attachment'] = null;
        }
      }

      final User sender = getUserFromMembers(message['uid'], users);

      messages.add(
        Message.fromJSON(
          message,
          sender: sender,
          isReaded: readed.contains(message['id']),
        ),
      );
    }
    return messages;
  }

  /// Отправка сообщения. Сервер сам назначает id и рассылает событие SEND.
  Future<void> sendMessage(int chatId, String text, int? repliedId) async {
    realtime.publish('/app/chats/$chatId', body: {
      'event': 'SEND',
      'payload': {
        'text': text,
        'localDateTime': DateTime.now().toIso8601String(),
        'zoneId': tz.local.name,
        'repliedMessage': repliedId,
      }
    });
  }

  Future<void> editMessage(int chatId, Message message) async {
    realtime.publish('/app/chats/$chatId', body: {
      'event': 'EDIT',
      'payload': message.toJSON()
    });
  }

  Future<void> deleteMessage(int chatId, Message message) async {
    realtime.publish('/app/chats/$chatId', body: {
      'event': 'DELETE',
      'payload': message.toJSON()
    });
  }

  Future<void> uploadAttachment(Uint8List bytes, int messageID) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes),
    });
    await dio.post('/messages/$messageID/attachment', data: form);
  }

  Future<ImageProvider> getAttachment(int id) async {
    final ImageProvider? attachmentProvider = attachmentProviders[id];
    if (attachmentProvider != null) {
      return attachmentProvider;
    }
    final url = await getAttachmentUrl(id);
    final provider = NetworkImage(url);
    attachmentProviders[id] = provider;
    return provider;
  }

  Future<String> getAttachmentUrl(int id) async {
    final res = await dio.get('/messages/$id/attachment');
    return res.data;
  }

  Future<void> setReaded(int chatId, Message message) async {
    realtime.publish('/app/chats/$chatId', body: {
      'event': 'READ',
      'payload': message.toJSON()
    });
  }

  Future<List<int>> getReadedMessages(int chatID) async {
    final res = await dio.get('/chats/$chatID/reads');
    return (res.data as List).map((e) => (e as num).toInt()).toList();
  }
}