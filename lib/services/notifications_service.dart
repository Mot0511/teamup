import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/models/models.dart' as models;
import 'package:teamup/features/user/user.dart';
import 'package:teamup/providers/notifications_provider.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

enum OS {android, windows, web}

Future<void> notificationHandler(RemoteMessage message, navigatorKey) async {
  await Firebase.initializeApp();
  final chatsRepository = ChatsRepository();
  final teamsRepository = TeamsRepository();
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
}

class NotificationsService {
  bool isOnline = false;
  bool isInChat = false;
  
  late final String userID;

  final supabase = GetIt.I<SupabaseClient>();
  final userRepository = GetIt.I<UserRepository>();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  Future<void> setFcmToken(String uid) async {
    if (!kIsWeb && Platform.isAndroid) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final token = await supabase.from('fcm_tokens').select().eq('user_id', uid);
        if (token.isEmpty) {
          await supabase.from('fcm_tokens').insert([
            {
              'user_id': uid,
              'fcm_token': fcmToken
            }
          ]);
        } else if (token[0]['fcm_token'] != fcmToken) {
          await supabase.from('fcm_tokens').update(
            {
              'fcm_token': fcmToken
            } 
          ).eq('user_id', uid);
        }
      }
    }
  }

  Future<void> redirect(message, navigatorKey) async {
    if (message != null) {
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
    }
  }

  Future<void> setListeners(GlobalKey<NavigatorState> navigatorKey, userdata, NotificationsProvider notificationsProvider, BuildContext context) async {
    if (userdata != null) {
      final userID = userdata.id;
      if (!kIsWeb && Platform.isAndroid) {
        FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
          await supabase.from('fcm_tokens').delete().eq('user_id', userID);
          await supabase.from('fcm_tokens').insert(
            {
              'user_id': userID,
              'fcm_token': fcmToken
            }
          );
        });

        // FirebaseMessaging.onMessage.listen((message) {
        //   notificationsProvider.showNotification(AssetImage('assets/images/default_avatar.png'), 'Matvey', 'Hello');
        // });
        FirebaseMessaging.onMessageOpenedApp.listen((message) => notificationHandler(message, navigatorKey));
        FirebaseMessaging.instance.getInitialMessage().then((message) => redirect(message, navigatorKey));
      }

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
            if (sender.uid != userID && !isOnline && Platform.isWindows) {
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