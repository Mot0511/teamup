import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/views/chat_view.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/teams/views/team_view.dart';

class MessagingService {
  MessagingService();

  static final supabase = GetIt.I<SupabaseClient>();
  static final chatsRepository = GetIt.I<ChatsRepository>();
  static final teamsRepository = GetIt.I<TeamsRepository>();

  static void init(String uid) async {
    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.getAPNSToken();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
        await supabase.from('fcm_tokens').insert([
        {
          'userID': uid,
          'fcm_token': fcmToken
        }
        ]);
    }
  }

  static void setListeners(GlobalKey<NavigatorState> navigatorKey) {
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      final userID = supabase.auth.currentUser!.id;
      await supabase.from('fcm_tokens').upsert(
        {
          'userID': userID,
          'fcm_token': fcmToken
        }
      );
    });

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
  }
}