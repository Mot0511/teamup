import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/user/models/account.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/services/realtime_service.dart';

class AuthProvider extends ChangeNotifier {

  final userRepository = GetIt.I<UserRepository>();
  final storage = GetIt.I<FlutterSecureStorage>();
  final userBloc = GetIt.I<UserBloc>();
  final notificationsService = GetIt.I<NotificationsService>();

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  Account? _account;
  Account? get account => _account;

  void _connectRealtime() {
    GetIt.I<RealtimeService>().connect();
  }

  Future<void> init() async {
    try {
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _connectRealtime();
      final Account account = await userRepository.getAccount();
      if (!account.isVerified) {
        _status = AuthStatus.notVerified;
        notifyListeners();
        return;
      }
      _account = account;
      _status = AuthStatus.authenticatedNoProfile;

      await _checkProfile();

      if (Platform.isAndroid) await _setFcmToken(account.uid);
      
      notifyListeners();
    } catch (e) {
      print('Ошибка при восстановлении авторизации');
      await userRepository.signout();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> login(
    String email,
    String password
  ) async {
    await userRepository.emailSignIn(email, password);
    _connectRealtime();
    _status = AuthStatus.authenticatedNoProfile;
    await _checkProfile();
    notifyListeners();
  }

  Future<void> register(
    String email,
    String password
  ) async {
    userRepository.emailSignUp(email, password);
    _status = AuthStatus.notVerified;
    notifyListeners();
  }

  Future<void> googleLogin() async {
    await userRepository.googleSignIn();
    _connectRealtime();
    _status = AuthStatus.authenticatedNoProfile;
    await _checkProfile();
    notifyListeners();
  }

  Future<void> discordLogin() async {
    await userRepository.discordSignIn();
    _connectRealtime();
    _status = AuthStatus.authenticatedNoProfile;
    await _checkProfile();
    notifyListeners();
  }

  Future<void> createProfile(User user) async {
    await userRepository.addUserdata(user);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> _checkProfile() async {
    try {
      await userRepository.getMe();
      userBloc.add(LoadUser());
      _status = AuthStatus.authenticated;
    } catch (_) {
      _account ??= await userRepository.getAccount();
      _status = AuthStatus.authenticatedNoProfile;
    }
  }

  Future<void> _setFcmToken(String uid) async {
     await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await notificationsService.setFcmToken(uid);
  }

  Future<void> logout() async {
    await userRepository.signout();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

}