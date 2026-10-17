import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/user/auth_gate.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/theme.dart';

enum LoginState {notLogined, noUserdata, logined}

class Teamup extends StatefulWidget {
  const Teamup({super.key});

  @override
  State<Teamup> createState() => _TeamupState();
}

class _TeamupState extends State<Teamup> with WidgetsBindingObserver {
  final userBloc = GetIt.I<UserBloc>();
  final userRepository = GetIt.I<UserRepository>();
  final storage = GetIt.I<FlutterSecureStorage>();

  final navigatorKey = GetIt.I<GlobalKey<NavigatorState>>();
  final scaffoldMessengerKey = GetIt.I<GlobalKey<ScaffoldMessengerState>>();
  
  void initState() {
    super.initState();
  }

  // @override
  // Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
  //   super.didChangeAppLifecycleState(state);
  //   final uid = supabase.auth.currentUser?.id;
  //   final channel = supabase.channel('isOnline-$uid');
  //   if (state == AppLifecycleState.resumed && uid != null) {
  //     await userRepository.setOnline();
  //     channel.sendBroadcastMessage(event: 'online', payload: {});
  //     notificationsService.isOnline = true;
  //     final pendingTeamID = await searchRepository.getPendingTeamID(uid);
  //     if (pendingTeamID == null && userBloc.state is UserStateLoaded) {
  //       searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user));
  //     }
  //   } else if ( 
  //     (state == AppLifecycleState.paused || 
  //     state == AppLifecycleState.inactive || 
  //     state == AppLifecycleState.detached) && uid != null
  //   ) {
  //     await userRepository.setOffline();
  //     channel.sendBroadcastMessage(event: 'offline', payload: {});
  //     notificationsService.isOnline = false;
  //   }
  // }


  // Future<void> onResumeApp() async {
  //   await userRepository.setOnline();
  //   notificationsService.isOnline = true;
  //   final pendingTeamID = await searchRepository.getPendingTeamID(uid);
  //   if (pendingTeamID == null && userBloc.state is UserStateLoaded) {
  //     searchBloc.add(StopSearching(user: (userBloc.state as UserStateLoaded).user));
  //   }
  // }

  // Future<void> onStopApp() async {
  //   await userRepository.setOffline();
  //   notificationsService.isOnline = false;
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      theme: theme,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: AuthGate()
    );
  }
}
