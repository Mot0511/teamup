import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/views/chat_view.dart';
import 'package:teamup/features/home/views/views.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/teams/views/team_view.dart';
import 'package:teamup/features/user/views/signin_view.dart';
import 'package:teamup/loading.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/theme.dart';

enum LoginState {notLogined, noUserdata, logined}

class Teamup extends StatefulWidget {
  const Teamup({super.key});

  @override
  State<Teamup> createState() => _TeamupState();
}

class _TeamupState extends State<Teamup> {

  final supabase = GetIt.I<SupabaseClient>();
  late final StreamSubscription<AuthState> _authStateSubscription;
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initState() {
    super.initState();
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
           await supabase.from('fcm_tokens').insert([
            {
              'userID': supabase.auth.currentUser?.id,
              'fcm_token': fcmToken
            }
           ]);
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      final userID = supabase.auth.currentUser?.id;
      if (userID != null) {
        await supabase.from('fcm_tokens').upsert(
          {
            'userID': userID,
            'fcm_token': fcmToken
          }
        );
      }
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

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      theme: theme,
      navigatorKey: navigatorKey,
      home: StreamBuilder(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Loading();
          }

          if (snap.data?.session == null) {
            return SigninView();
          }

          return NavScreen();
        }
      )
    );
  }
}
