import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/home/views/views.dart';
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
