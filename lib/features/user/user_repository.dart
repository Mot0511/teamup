import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:teamup/features/user/exceptions/auth_exception.dart';
import 'package:teamup/features/user/models/account.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/features/user/services/discord_auth_service.dart';
import 'package:teamup/features/user/services/google_auth_service.dart';
import 'package:teamup/services/realtime_service.dart';

class UserRepository {
  final storage = GetIt.I<FlutterSecureStorage>();
  final dio = GetIt.I<Dio>();
  final realtime = GetIt.I<RealtimeService>();

  final Map<String, ImageProvider> avatarProviders = {};

  Future<void> _setToken(String accessToken) async {
    await storage.write(key: 'access_token', value: accessToken);
  }

  Future<void> _deleteToken() async {
    await storage.delete(key: 'access_token');
  }

  /// Текущий uid пользователя — из subject JWT (доступного в secure storage).
  Future<String?> currentUid() async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) return null;
      final jwt = JWT.decode(token);
      final sub = jwt.payload['sub'];
      return sub?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> googleSignIn() async {
    final String idToken = await _googleIdToken();

    final res = await dio.post("/auth/google", data: {
      'provider_id_token': idToken,
    });

    final token = res.data['accessToken'];
    if (token != null) {
      await _setToken(token);
    }
  }

  /// id_token из OAuth-провайдера: на платформах без google_sign_in
  /// (Windows/Linux) используется браузерный loopback-поток.
  Future<String> _googleIdToken() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return GetIt.I<GoogleAuthService>().getIdToken();
    }

    final clientIDs = {
      'android': '677191252450-ibg34ij1u3kcjo5pid4ptjtf8dadp10f.apps.googleusercontent.com',
      'ios': '677191252450-fuf25incf7lc9ccboqsrqt1rtpfqd592.apps.googleusercontent.com',
      'macos': '677191252450-jmd0vvr6gqhv4lm255n2uf1l7iinb0s9.apps.googleusercontent.com',
      'web': '677191252450-s6a7kuf9dek6arhufeot9i968a8bhloh.apps.googleusercontent.com'
    };

    final googleSignIn = GoogleSignIn(
      clientId: Platform.isAndroid ? clientIDs['android']! : clientIDs['web']!,
      serverClientId: Platform.isMacOS ? null : clientIDs['web'],
      scopes: ["profile", "email"],
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return idToken;
  }

  /// Вход через Discord: браузерный loopback-поток (см. [DiscordAuthService])
  /// возвращает `code`, бэкенд обменивает его на свой JWT
  /// (`POST /auth/discord`), который сохраняется в secure storage.
  Future<void> discordSignIn() async {
    if (kIsWeb) throw UnsupportedError('Discord вход не поддерживается');

    final String code = await GetIt.I<DiscordAuthService>().getCode();

    final res = await dio.post("/auth/discord", data: {
      'code': code,
    });

    final token = res.data;
    if (token != null) {
      await _setToken(token);
    }
  }

  Future<void> emailSignIn(String email, String password) async {
    try {
      final res = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      await _setToken(res.data['accessToken']);
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 401:
          throw AuthException("Неверный логин или пароль");
        case 404:
          throw AuthException("Пользователь не найден");
      }
      throw AuthException('Сервер недоступен, попробуйте позже');
    }
    
  }

  Future<void> emailSignUp(String email, String password) async {
    await dio.post('/auth/register', data: {
      'email': email,
      'password': password
    });
  }

  Future<void> resetPassword(String email) async {
    await dio.post('/auth/forgot', data: {
      'email': email,
    });
  }

  Future<void> signout() async {
    try {
      await GoogleSignIn().disconnect();
    } on Exception catch (_) {}

    realtime.disconnect();
    await _deleteToken();
  }

  Future<void> addUserdata(User user) async {
    await dio.post('/users/', data: user.toJSON());
  }

  Future<User> getUserdata(String uid) async {
    final response = await dio.get('/users/$uid');
    return User.fromJSON(response.data);
  }

  Future<User> getMe() async {
    final response = await dio.get('/users/me');
    return User.fromJSON(response.data);
  }

  Future<Account> getAccount() async {
    final res = await dio.get('/auth/me');
    return Account.fromJson(res.data);
  }

  Future<List<User>> getUsersByChat(int teamID) async {
    final res = await dio.get('/chats/$teamID/users');
    return (res.data as List).map((user) => User.fromJSON(user)).toList();
  }

  Future<bool> isUsernameExists(String username) async {
    // final res = await dio.get('/auth/username/$username/exists');
    // return res.data;
    return false;
  }

  Future<bool> isEmailExists(String email) async {
    final res = await dio.get('/auth/email/$email/exists');
    return res.data;
  }

  Future<void> updateUser(User user) async {
    await dio.put('/users/', data: user.toJSON());
  }

  Future<ImageProvider> getAvatar(String uid) async {
    final ImageProvider? avatarProvider = avatarProviders[uid];
    if (avatarProvider != null) {
      return avatarProvider;
    }
    try {
      final url = await dio.get('/users/$uid/avatar');
      final provider = NetworkImage(url.data);
      avatarProviders[uid] = provider;
      return provider;
    } on DioException catch (_) {
      final provider = AssetImage('assets/images/default_avatar.png');
      avatarProviders[uid] = provider;
      return provider;
    }
  }

  Future<void> uploadAvatar(Uint8List avatarBytes, String uid) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(avatarBytes, filename: "$uid-avatar.png"),
    });
    await dio.post("/users/avatars", data: form);
  }

  void updateAvatarCache(String uid, ImageProvider avatar) {
    avatarProviders[uid] = avatar;
  }

  Future<void> addFriend(User user, User friend) async {
    await dio.post('/users/friends', data: {
      'fromUser': user.uid,
      'toUser': friend.uid,
    });
  }

  Future<void> allowFriendRequest(String fromUser, String toUser) async {
    await dio.put('/users/friends', data: {
      'fromUser': fromUser,
      'toUser': toUser,
    });
  }

  Future<List<Friendship>> getFriends(String uid) async {
    final res = await dio.get('/users/friends/$uid');
    final List data = (res.data as List).cast<Map>().toList();

    final List<Friendship> friends = [];
    for (Map row in data) {
      final String fromUser = '${row['fromUser']}';
      final String toUser = '${row['toUser']}';
      final bool status = row['status'] ?? false;

      final String friendUid = fromUser == uid ? toUser : fromUser;
      final User friend = await getUserdata(friendUid);

      FriendState state;
      if (status) {
        state = FriendState.friend;
      } else {
        state = fromUser == uid ? FriendState.iRequested : FriendState.requestedToMe;
      }

      friends.add(Friendship(friend: friend, state: state));
    }

    return friends;
  }

  Future<void> removeFriend(String user1, String user2) async {
    await dio.delete('/users/friends', data: {
      'fromUser': user1,
      'toUser': user2,
    });
  }

  void setOnline() {
    realtime.publish('/realtime/user/status/true');
  }

  void setOffline() {
    realtime.publish('/realtime/user/status/false');
  }

  Future<bool> getIsOnline(String uid) async {
    final res = await dio.get('/users/status/$uid');
    return res.data ?? false;
  }
}