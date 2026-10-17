import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google OAuth2 (authorization code + PKCE) для десктопных платформ
/// (Windows/Linux), где плагин google_sign_in не поддерживается.
///
/// Поток: открываем системный браузер → Google возвращает `code` на локальный
/// redirect (`http://localhost:23790`) → обмениваем код на токены → отдаём
/// `id_token` для передачи в `POST /auth/google`.
///
/// Google разрешает http-loopback только для OAuth-клиентов типа «Desktop app»,
/// поэтому требуется создать такой клиент и указать его id в `.env`:
/// `GOOGLE_DESKTOP_CLIENT_ID=<client_id>` (нет секрета — работает PKCE).
/// Важно: этот же id надо добавить в доверенные аудитории бэкенда
/// (проверка id_token в `/auth/google`).
class GoogleAuthService {
  GoogleAuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static String get clientId {
    final String? id = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'];
    if (id == null || id.trim().isEmpty) {
      throw StateError(
        'GOOGLE_DESKTOP_CLIENT_ID не задан в .env. '
        'Создайте OAuth-клиент типа "Desktop app" в Google Cloud Console '
        '(проект 677191252450) и укажите его client_id.',
      );
    }
    return id.trim();
  }

  static String? get _clientSecret => dotenv.env['GOOGLE_DESKTOP_CLIENT_SECRET'];

  static const String _authEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String _tokenEndpoint = 'https://oauth2.googleapis.com/token';

  static const int redirectPort = 23790;
  static const String redirectUri =
      'http://localhost:$redirectPort';

  /// Получает id_token пользователя через OAuth2 authorization code + PKCE.
  Future<String> getIdToken() async {
    final verifier = _createCodeVerifier();
    final challenge = _codeChallenge(verifier);

    final List<HttpServer> servers = <HttpServer>[];
    try {
      servers.add(await HttpServer.bind(InternetAddress.loopbackIPv4, redirectPort));
      try {
        servers.add(await HttpServer.bind(
          InternetAddress.loopbackIPv6,
          redirectPort,
          v6Only: true,
        ));
      } on SocketException {}

      final Future<HttpRequest> anyRequest = Future.any(
        servers.map((server) => server.first),
      );

      final Uri uri = Uri.parse(_authEndpoint).replace(queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'access_type': 'offline',
        'prompt': 'select_account',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      });

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      final HttpRequest request = await anyRequest.timeout(
        const Duration(minutes: 3),
      );

      await _respondOk(request);

      final Map<String, String> query = request.uri.queryParameters;
      final String? error = query['error'];
      if (error != null) {
        throw StateError('Google OAuth error: $error');
      }
      final String? code = query['code'];
      if (code == null) {
        throw StateError('Google OAuth: no code in redirect');
      }

      final Map<String, dynamic> tokens = await _exchangeCode(
        code: code,
        verifier: verifier,
      );
      final String? idToken = tokens['id_token']?.toString();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google OAuth: no id_token in exchange response');
      }
      return idToken;
    } finally {
      for (final HttpServer server in servers) {
        await server.close(force: true);
      }
    }
  }

  Future<void> _respondOk(HttpRequest request) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(
        '<html><body><center><h3>Готово! Это окно можно закрыть.</h3></center></body></html>',
      );
    await request.response.close();
  }

  Future<Map<String, dynamic>> _exchangeCode({
    required String code,
    required String verifier,
  }) async {
    final Map<String, String> data = {
      'code': code,
      'client_id': clientId,
      'code_verifier': verifier,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUri,
    };
    final String? secret = _clientSecret;
    if (secret != null && secret.isNotEmpty) {
      data['client_secret'] = secret.trim();
    }

    try {
      final Response<dynamic> res = await _dio.post(
        _tokenEndpoint,
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: data,
      );
      return (res.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      final String? googleError = e.response?.data is Map
          ? (e.response?.data as Map)['error']?.toString()
          : null;
      final String? description = e.response?.data is Map
          ? (e.response?.data as Map)['error_description']?.toString()
          : null;
      throw StateError(
        'Google token exchange failed (HTTP ${e.response?.statusCode}).'
        '${googleError != null ? ' error=$googleError' : ''}'
        '${description != null && description.isNotEmpty ? ' — $description' : ''}',
      );
    }
              }

  String _createCodeVerifier() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final Random random = Random.secure();
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _codeChallenge(String verifier) {
    return base64Url
        .encode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');
  }
}