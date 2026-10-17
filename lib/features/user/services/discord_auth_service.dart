import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

/// Discord OAuth2 (authorization code) для нативных платформ.
///
/// Поток: открываем системный браузер → Discord возвращает `code` на локальный
/// redirect (`http://localhost:23791`) → отдаём `code` для передачи в
/// `POST /auth/discord`.
///
/// В отличие от Google у Discord нет `id_token`, а обмен `code` на токен
/// возможен только с `client_secret` (PKCE не поддерживается), поэтому обмен
/// выполняет бэкенд. В клиенте хранится только `DISCORD_CLIENT_ID` из `.env`,
/// секрет — в конфигурации бэкенда.
///
/// В приложении Discord Developer Portal необходимо добавить redirect URI
/// `http://localhost:23791` (OAuth2).
class DiscordAuthService {
  static String get clientId {
    final String id = dotenv.env['DISCORD_CLIENT_ID']!;
    return id.trim();
  }

  static const String _authEndpoint = 'https://discord.com/oauth2/authorize';

  static const int redirectPort = 23791;
  static const String redirectUri = 'http://localhost:$redirectPort';

  /// Получает authorization code пользователя через браузерный loopback-поток.
  Future<String> getCode() async {
    final String state = _createState();

    final List<HttpServer> servers = <HttpServer>[];
    try {
      servers.add(
        await HttpServer.bind(InternetAddress.loopbackIPv4, redirectPort),
      );
      try {
        servers.add(await HttpServer.bind(
          InternetAddress.loopbackIPv6,
          redirectPort,
          v6Only: true,
        ));
      } on SocketException catch (_) {}

      final Future<HttpRequest> anyRequest = Future.any(
        servers.map((server) => server.first),
      );

      final Uri uri = Uri.parse(_authEndpoint).replace(queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'identify email',
        'state': state,
      });

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      final HttpRequest request = await anyRequest.timeout(
        const Duration(minutes: 3),
      );

      await _respondOk(request);

      final Map<String, String> query = request.uri.queryParameters;
      final String? error = query['error'];
      if (error != null) {
        throw StateError('Discord OAuth error: $error');
      }
      if (query['state'] != state) {
        throw StateError('Discord OAuth: state mismatch (possible CSRF)');
      }
      final String? code = query['code'];
      if (code == null) {
        throw StateError('Discord OAuth: no code in redirect');
      }
      return code;
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

  String _createState() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
