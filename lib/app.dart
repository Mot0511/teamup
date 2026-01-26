import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/loading.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/providers/notifications_provider.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/theme.dart';
import 'package:flutter_window_close/flutter_window_close.dart';

enum LoginState {notLogined, noUserdata, logined}

class Teamup extends StatefulWidget {
  const Teamup({super.key});

  @override
  State<Teamup> createState() => _TeamupState();
}

class _TeamupState extends State<Teamup> with WidgetsBindingObserver {

  final supabase = GetIt.I<SupabaseClient>();
  late final StreamSubscription<AuthState> _authStateSubscription;
  late final StreamSubscription<Uri> appLinksSubscription;

  final userBloc = GetIt.I<UserBloc>();
  final searchBloc = GetIt.I<SearchBloc>();
  final chatsRepository = GetIt.I<ChatsRepository>();
  final teamsRepository = GetIt.I<TeamsRepository>();
  final userRepository = GetIt.I<UserRepository>();
  final searchRepository = GetIt.I<SearchRepository>();
  final notificationsService = GetIt.I<NotificationsService>();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  final appLinks = AppLinks();

  void initState() {
    super.initState();

    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final userdata = supabase.auth.currentUser;
      if (userdata?.id != null) {
        if (data.event == AuthChangeEvent.signedIn) {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        }
        await notificationsService.setFcmToken(userdata!.id);
        final users = await supabase.from('users').select().eq('uid', userdata.id);
        if (users.isEmpty) {
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (_) => UserFormView(userdata: userdata))
          );
          return;
        }
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => NavScreen())
        );
        
        userBloc.add(LoadUser(uid: userdata.id));
        await userRepository.setOnline(userdata.id);

        final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
        await notificationsService.setListeners(navigatorKey, userdata, notificationsProvider, context);
        
        WidgetsBinding.instance.addObserver(this);
        if (Platform.isWindows) {
          FlutterWindowClose.setWindowShouldCloseHandler(() async {
            await userRepository.setOffline(userdata.id);
            return true;
          });
        }
      }
    });
  }

   @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    final uid = supabase.auth.currentUser?.id;
    if (state == AppLifecycleState.resumed && uid != null) {
      await userRepository.setOnline(uid);
      notificationsService.isOnline = true;
      final pendingTeamID = await searchRepository.getPendingTeamID(uid);
      if (pendingTeamID == null && userBloc.state is UserStateLoaded) {
        searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user));
      }
    } else if ( 
      (state == AppLifecycleState.paused || 
      state == AppLifecycleState.inactive || 
      state == AppLifecycleState.detached) && uid != null
    ) {
      await userRepository.setOffline(uid);
      notificationsService.isOnline = false;
    }
  }


  Future<void> onResumeApp() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      await userRepository.setOnline(uid);
      notificationsService.isOnline = true;
      final pendingTeamID = await searchRepository.getPendingTeamID(uid);
      if (pendingTeamID == null && userBloc.state is UserStateLoaded) {
        searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user));
      }
    }
  }

  Future<void> onStopApp() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      await userRepository.setOffline(uid);
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
