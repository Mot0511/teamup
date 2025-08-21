import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/views/chat_view.dart';
import 'package:teamup/features/home/views/views.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/teams/views/team2_view.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/views/signin_view.dart';
import 'package:teamup/loading.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/theme.dart';
import 'package:teamup/features/user/views/user_form_view.dart';

enum LoginState {notLogined, noUserdata, logined}

class Teamup extends StatefulWidget {
  const Teamup({super.key});

  @override
  State<Teamup> createState() => _TeamupState();
}

class _TeamupState extends State<Teamup> with WidgetsBindingObserver {

  final supabase = GetIt.I<SupabaseClient>();
  late final StreamSubscription<AuthState> _authStateSubscription;

  final userBloc = GetIt.I<UserBloc>();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();
  final userRepository = GetIt.I<UserRepository>();
  final notificationsService = GetIt.I<NotificationsService>();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initState() {
    super.initState();
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final userdata = supabase.auth.currentUser;
      if (userdata?.id != null) {
        if (data.event == AuthChangeEvent.signedIn) {
          notificationsService.init(userdata!.id);
        }
        final users = await supabase.from('users').select().eq('uid', userdata!.id);
        if (users.isEmpty) {
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (_) => UserFormView(userdata: userdata))
          );
          return;
        }
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => NavScreen())
        );
        
        
        userBloc.add(LoadUser(uid: userdata!.id));
        userRepository.setOnline(userdata.id);
        notificationsService.setListeners(navigatorKey);
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final uid = supabase.auth.currentUser?.id;
    if (state == AppLifecycleState.resumed && uid != null) {
      userRepository.setOnline(uid);
      notificationsService.isOnline = true;
    } else if (
      (state == AppLifecycleState.paused || 
      state == AppLifecycleState.inactive || 
      state == AppLifecycleState.detached) && uid != null
    ) {
      userRepository.setOffline(uid);
      notificationsService.isOnline = false;
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
