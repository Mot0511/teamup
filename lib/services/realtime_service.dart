import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

typedef StompMessageCallback = void Function(dynamic body);

class RealtimeService {
  RealtimeService({
    required this.url,
    required this.getAccessToken,
  });

  final String url;
  final Future<String?> Function() getAccessToken;

  StompClient? _client;
  final List<_RealtimeSubscription> _subscriptions = [];

  bool get isActive => _client?.isActive ?? false;

  bool get isConnected => _client?.connected ?? false;

  /// Подключает и активирует STOMP-клиент (с автопереподключением).
  Future<void> connect() async {
    if (_client != null) return;

    // Единая карта заголовков: мутация в beforeConnect видна и в HTTP Upgrade
    // (webSocketConnectHeaders читается при WebSocket.connect), и в STOMP CONNECT.
    final connectHeaders = <String, String>{};

    final client = StompClient(
      config: StompConfig(
        url: url,
        useSockJS: true,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        stompConnectHeaders: connectHeaders,
        webSocketConnectHeaders: connectHeaders,
        beforeConnect: () async {
          final accessToken = await getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            connectHeaders['Authorization'] = 'Bearer $accessToken';
          } else {
            connectHeaders.remove('Authorization');
          }
        },
        onConnect: (frame) {
          debugPrint('[STOMP] connected');
          _resubscribeAll();
        },
        onStompError: (frame) {
          debugPrint('[STOMP] STOMP error: ${frame.body}');
        },
        onWebSocketError: (error) {
          debugPrint('[STOMP] websocket error: $error');
        },
        onWebSocketDone: () {
          debugPrint('[STOMP] websocket closed');
        },
        onDebugMessage: (message) {
          debugPrint('[STOMP] $message');
        },
      ),
    );

    _client = client;
    client.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    for (final subscription in _subscriptions.toList()) {
      subscription.detach();
    }
    _subscriptions.clear();
  }

  /// Подписка на destination. Возвращает функцию отписки.
  StompUnsubscribe subscribe(String destination, StompMessageCallback callback) {
    final subscription = _RealtimeSubscription(destination, callback);
    _subscriptions.add(subscription);

    if (isConnected) {
      subscription.attach(_client!);
    }

    return ({Map<String, String>? unsubscribeHeaders}) {
      subscription.detach();
      _subscriptions.remove(subscription);
    };
  }

  /// Отправка JSON-сообщения на destination.
  void publish(
    String destination, {
    Object? body,
    Map<String, String>? headers,
  }) {
    final client = _client;
    if (client == null) {
      debugPrint('[STOMP] client is not active, cannot publish to $destination');
      return;
    }
    if (!isConnected) {
      debugPrint('[STOMP] not connected, cannot publish to $destination');
      return;
    }

    client.send(
      destination: destination,
      body: body is String ? body : jsonEncode(body),
      headers: headers,
    );
  }

  void _resubscribeAll() {
    final client = _client;
    if (client == null) return;
    for (final subscription in _subscriptions) {
      subscription.attach(client);
    }
  }
}

class _RealtimeSubscription {
  _RealtimeSubscription(this.destination, this.callback);

  final String destination;
  final StompMessageCallback callback;

  StompUnsubscribe? _unsubscribe;

  void attach(StompClient client) {
    _unsubscribe?.call();
    _unsubscribe = client.subscribe(
      destination: destination,
      callback: (frame) {
        final String? body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          callback(jsonDecode(body));
        } on FormatException catch (e) {
          debugPrint('[STOMP] failed to parse frame body: $e');
        }
      },
    );
  }

  void detach() {
    _unsubscribe?.call();
    _unsubscribe = null;
  }
}