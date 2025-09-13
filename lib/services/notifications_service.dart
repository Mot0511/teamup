import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/views/chat_view.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/teams/views/team2_view.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/models/user.dart' as models;
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum OS {android, windows, web}

@pragma('vm:entry-point')
Future<void> onBgMessage(RemoteMessage message) async {
  final notificationService = GetIt.I<NotificationsService>();
  print('BACKGROUND HANDLER');

  final androidDetails = AndroidNotificationDetails(
    'main_channel', // ID канала
    'Основной канал', // Имя канала
    importance: Importance.max,
    priority: Priority.high,
  );

  final NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await notificationService.notifications!.show(
    int.parse(message.data['id']) ~/ 10000000000,
    message.data['title'],
    message.data['body'],
    details,
  );
}

class NotificationsService {
  bool isOnline = false;
  
  late final String userID;

  final supabase = GetIt.I<SupabaseClient>();
  final userRepository = GetIt.I<UserRepository>();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  FlutterLocalNotificationsPlugin? notifications;

  Future<void> init() async {
    notifications = FlutterLocalNotificationsPlugin();

    final settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings()
    );

    await notifications!.initialize(settings);
  } 

  Future<void> setFcmToken(String uid) async {
    if (Platform.isAndroid) {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.getAPNSToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await supabase.from('fcm_tokens').upsert([
          {
            'user_id': uid,
            'fcm_token': fcmToken
          }
        ]);
      }
    }
  }

  void setListeners(GlobalKey<NavigatorState> navigatorKey) async {
    final userID = supabase.auth.currentUser!.id;
    if (Platform.isAndroid) {
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
        await supabase.from('fcm_tokens').delete().eq('user_id', userID);
        await supabase.from('fcm_tokens').insert(
          {
            'user_id': userID,
            'fcm_token': fcmToken
          }
        );
      });

      // FirebaseMessaging.onBackgroundMessage(onBgMessage);

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        final type = message.data['screen'].split('-')[0];
        final id = message.data['screen'].split('-')[1];

        if (type == 'chat') {
          final chat = await chatsRepository.getChat(int.parse(id));
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => ChatView(chat: chat))
          );
        } else {
          final team = await teamsRepository.getTeam(int.parse(id));
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => TeamView(team: team))
          );
        }

      });

    } else {
      final data = await supabase.from('members').select('chat').eq('member', userID);
      final chats = data.map((chat) => chat['chat']);
      final channel = supabase.channel('notification-channel');
      channel.onPostgresChanges(
        table: 'messages',
        event: PostgresChangeEvent.insert,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.inFilter,
          column: 'chat',
          value: chats
        ),
        callback: (payload) async {
          final models.User sender = await userRepository.getUserdata(payload.newRecord['sender']);
          if (sender.uid != userID && !isOnline) {
            showNotification(payload.newRecord['id'].toString(), sender.username, payload.newRecord['text']);
          }
        }
      );

      channel.subscribe();
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