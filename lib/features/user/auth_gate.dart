import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/enums.dart';
import 'package:teamup/features/user/providers/auth_provider.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/loading.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/services/notifications_service.dart';

class AuthGate extends StatefulWidget {
  AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final userRepository = GetIt.I<UserRepository>();

  final teamsRepository = GetIt.I<TeamsRepository>();
  final navigatorKey = GetIt.I<GlobalKey<NavigatorState>>();
  final scaffoldMessengerKey = GetIt.I<GlobalKey<ScaffoldMessengerState>>();
  final notificationsService = GetIt.I<NotificationsService>();

  late final StreamSubscription appLinksSub;

  Future<void> initListeners() async {
    initAppLinks();
    await notificationsService.setListeners(navigatorKey, context);
  }

  Future<void> initAppLinks() async {
    final appLinks = AppLinks();
    final link = await appLinks.getInitialLink();
    if (link != null) {
      handleAppLink(link);
    }
    
    appLinksSub = appLinks.uriLinkStream.listen((uri) {
      handleAppLink(uri);
    });
  }

  Future<void> handleAppLink(Uri uri) async {
    final segments = uri.toString().split('/');
    switch (segments[2]) {
      case 'invite':
        final teamID = int.parse(segments[3]);
        final number = int.parse(segments[4]);
        try {
          final Team team = await teamsRepository.acceptInvitation(teamID, number);
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => TeamView(team: team)),
          );
        } on DioException catch (e) {
          scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Ошибка принятия приглашения в команду')));
        }
        break;

      case 'profile':
        final uid = segments[3];
        final user = await userRepository.getUserdata(uid);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ProfileView(user: user)),
        );
    }

  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.loading:
        return Loading();
      case AuthStatus.authenticated:
        initListeners();
        return NavScreen();
      case AuthStatus.authenticatedNoProfile:
        return UserFormView(account: authProvider.account!);
      case AuthStatus.unauthenticated:
        return SigninView();
      case AuthStatus.notVerified:
        return EmailConfirmationView();
    }
  }
}