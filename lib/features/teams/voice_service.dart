import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceService {
  final String roomId;
  final String selfId;
  final void Function(List<String> peers) onPeersChanged;

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  MediaStream? _localStream;

  // peerId -> RTCPeerConnection
  final Map<String, RTCPeerConnection> _pcs = {};
  // если кандидаты приходят до remoteDescription
  final Map<String, List<RTCIceCandidate>> _pendingCandidates = {};
  final Map<String, List<MediaStreamTrack>> _remoteAudioTracks = {};

  List<String> get peers => _pcs.keys.toList()..sort();

  VoiceService({
    required this.roomId,
    required this.selfId,
    required this.onPeersChanged,
  });

  Future<void> init() async {
    // 1) локальный аудио поток
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });

    // 2) подписка на канал комнаты
    _channel = _supabase.channel(roomId);

    _channel!
      .onBroadcast(
        event: 'signal',
        callback: (payload, [ref]) {
          // нормализация: иногда SDK кладёт всё в payload.payload
          final data = (payload is Map && payload.containsKey('payload'))
              ? payload['payload']
              : payload;
          if (data is Map<String, dynamic>) {
            _handleMessage(data);
          } else if (data is Map) {
            _handleMessage(Map<String, dynamic>.from(data));
          }
        },
      )
      .subscribe((status, [err]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _send({'action': 'join', 'peerId': selfId});
        } else if (err != null) {
          // Можно повесить retry/backoff
          // debugPrint('Supabase subscribe error: ${err.message}');
        }
      });
  }

  // Отправка сигнального сообщения
  void _send(Map<String, dynamic> msg) {
    _channel?.sendBroadcastMessage(
      event: 'signal',
      payload: {...msg, 'from': selfId},
    );
  }

  Future<void> leave() async {
    _send({'action': 'leave', 'peerId': selfId});
    for (final pc in _pcs.values) {
      try { await pc.close(); } catch (_) {}
    }
    _pcs.clear();
    _pendingCandidates.clear();

    try { await _localStream?.dispose(); } catch (_) {}
    _localStream = null;
    onPeersChanged(peers);

    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  void dispose() { leave(); }

  Future<void> setMuted(bool muted) async {
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = !muted;
    }
    if (muted) {
      _send({'action': 'remoteVoiceOff'});
    } else {
      _send({'action': 'remoteVoiceOn'});
    }
  }

  Future<void> setRemoteMuted(String peerId, bool muted) async {
    final tracks = _remoteAudioTracks[peerId];
    if (tracks != null) {
      for (final t in tracks) {
        t.enabled = !muted;
      }
    }
  }

  String connectionStateOf(String peerId) {
    final pc = _pcs[peerId];
    if (pc == null) return 'disconnected';
    return pc.iceConnectionState?.toString().split('.').last ?? 'unknown';
  }

  // Создание/настройка PC на пира
  Future<RTCPeerConnection> _createPcFor(String peerId, {bool isCaller = false}) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          "urls": "turn:global.relay.metered.ca:80",
          "username": "5db6bd697c3849fa85812cb3",
          "credential": "UiNaqoi4aJNKIkTx",
        },
        {
          "urls": "turn:global.relay.metered.ca:80?transport=tcp",
          "username": "5db6bd697c3849fa85812cb3",
          "credential": "UiNaqoi4aJNKIkTx",
        },
        {
          "urls": "turn:global.relay.metered.ca:443",
          "username": "5db6bd697c3849fa85812cb3",
          "credential": "UiNaqoi4aJNKIkTx",
        },
        {
          "urls": "turns:global.relay.metered.ca:443?transport=tcp",
          "username": "5db6bd697c3849fa85812cb3",
          "credential": "UiNaqoi4aJNKIkTx",
        },
      ],
    };

    final pc = await createPeerConnection(config);

    // добавляем локальный аудио-трек
    final local = _localStream;
    if (local != null) {
      for (final track in local.getTracks()) {
        await pc.addTrack(track, local);
      }
    }

    // входящие треки (аудио автоматически проигрывается)
    pc.onTrack = (event) {
      for (final track in event.streams.first.getAudioTracks()) {
        _remoteAudioTracks.putIfAbsent(peerId, () => []).add(track);
      }
    };

    // отправка ICE
    pc.onIceCandidate = (c) {
      if (c.candidate != null) {
        _send({
          'action': 'candidate',
          'to': peerId,
          'candidate': c.toMap(),
        });
      }
    };

    _pcs[peerId] = pc;
    onPeersChanged(peers);

    if (isCaller) {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _send({'action': 'offer', 'to': peerId, 'sdp': offer.sdp});
    }

    return pc;
  }

  // Обработка входящих сигналов
  Future<void> _handleMessage(Map<String, dynamic> msg) async {
    final action = msg['action'] as String?;
    final from = (msg['peerId'] ?? msg['from'])?.toString();
    if (from == null || from == selfId) return;

    switch (action) {
      case 'join':
        // новый участник → инициируем звонок ему
        if (!_pcs.containsKey(from)) {
          await _createPcFor(from, isCaller: true);
        }
        break;

      case 'leave':
        _removePeer(from);
        break;

      case 'offer':
        final pc = _pcs[from] ?? await _createPcFor(from, isCaller: false);
        await pc.setRemoteDescription(RTCSessionDescription(msg['sdp'] as String, 'offer'));
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        _send({'action': 'answer', 'to': from, 'sdp': answer.sdp});
        // применяем отложенные кандидаты
        await _flushPending(from);
        break;

      case 'answer':
        final pcAns = _pcs[from];
        if (pcAns != null) {
          await pcAns.setRemoteDescription(RTCSessionDescription(msg['sdp'] as String, 'answer'));
          await _flushPending(from);
        }
        break;

      case 'candidate':
        final pcCand = _pcs[from];
        final c = msg['candidate'] as Map<String, dynamic>;
        final ice = RTCIceCandidate(
          c['candidate'] as String?,
          c['sdpMid'] as String?,
          (c['sdpMLineIndex'] is int)
              ? c['sdpMLineIndex'] as int
              : (c['sdpMLineIndex'] as num?)?.toInt(),
        );
        if (pcCand != null) {
          await pcCand.addCandidate(ice);
        } else {
          _pendingCandidates.putIfAbsent(from, () => []).add(ice);
        }
        break;
    }
  }

  Future<void> _flushPending(String peerId) async {
    final pc = _pcs[peerId];
    if (pc == null) return;
    final list = _pendingCandidates.remove(peerId);
    if (list == null) return;
    for (final c in list) {
      try { await pc.addCandidate(c); } catch (_) {}
    }
  }

  void _removePeer(String peerId) {
    final pc = _pcs.remove(peerId);
    try { pc?.close(); } catch (_) {}
    _pendingCandidates.remove(peerId);
    _remoteAudioTracks.remove(peerId);
    onPeersChanged(peers);
  }
}