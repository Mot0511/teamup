import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/providers/notifications_provider.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

enum OS {android, windows, web}

Future<void> notificationHandler(RemoteMessage message, navigatorKey) async {
  await Firebase.initializeApp();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final userRepository = GetIt.I<UserRepository>();
  final data = message.data;
  final type = data['type'];

  if (type == 'new_message') {
    final chatId = int.tryParse('${data['chatId']}');
    if (chatId != null) {
      final chat = await chatsRepository.getChat(chatId);
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ChatView(chat: chat))
      );
    }
  } else if (type == 'search_complete') {
    // uid — участник набранной команды; открываем команду через его/её чаты нельзя,
    // поэтому открываем профиль.
    final uid = data['uid'];
    if (uid != null) {
      final user = await userRepository.getUserdata(uid);
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ProfileView(user: user))
      );
    }
  } else if (type == 'friend_request') {
    final fromUser = data['fromUser'];
    if (fromUser != null) {
      final user = await userRepository.getUserdata(fromUser);
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ProfileView(user: user))
      );
    }
  }
}

class NotificationsService {
  bool isOnline = false;
  bool isInChat = false;

  late final String userID;

  final dio = GetIt.I<Dio>();
  final userRepository = GetIt.I<UserRepository>();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  Future<void> setFcmToken(String uid) async {
    if (!kIsWeb && Platform.isAndroid) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await dio.post('/fcm/token', queryParameters: {'fcm_token': fcmToken});
      }
    }
  }

  Future<void> deleteFcmToken() async {
    if (!kIsWeb && Platform.isAndroid) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await dio.delete('/fcm/token', queryParameters: {'fcm_token': fcmToken});
      }
    }
  }

  Future<void> redirect(message, navigatorKey) async {
    if (message != null) {
      final data = message.data;
      final type = data['type'];
      if (type == 'new_message') {
        final chatId = int.tryParse('${data['chatId']}');
        if (chatId != null) {
          final chat = await chatsRepository.getChat(chatId);
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => ChatView(chat: chat))
          );
        }
      }
    }
  }

  Future<void> setListeners(GlobalKey<NavigatorState> navigatorKey, BuildContext context) async {
    if (!kIsWeb && Platform.isAndroid) {
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
        await dio.post('/fcm/token', queryParameters: {'fcm_token': fcmToken});
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) => notificationHandler(message, navigatorKey));
      FirebaseMessaging.instance.getInitialMessage().then((message) => redirect(message, navigatorKey));
    }
  }

  void showNotification(String id, String title, String body) async {
    final winNotifyPlugin = WindowsNotification(applicationId: 'Teamup');
    NotificationMessage message = NotificationMessage.fromPluginTemplate(
      id,
      title,
      body,
    );
    winNotifyPlugin.showNotificationPluginTemplate(message);
  }
}