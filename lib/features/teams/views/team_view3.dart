import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TeamView extends StatefulWidget {
  final Team team;

  const TeamView({required this.team});

  @override
  _GroupVideoChatScreenState createState() => _GroupVideoChatScreenState();
}

class _GroupVideoChatScreenState extends State<TeamView> {
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  late WebSocketChannel _channel;
  MediaStream? _localStream;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isVideoOff = false;
  final id = Random().nextInt(100);

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _initWebSocket();
    _initLocalStream();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> _initLocalStream() async {
    final mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      print('Ошибка получения медиапотока: $e');
    }
  }

  void _initWebSocket() {
    
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.0.75:8000/ws/${widget.team.id}/$id'),
    );

    _channel.stream.listen((message) {
      final data = json.decode(message);
      final sender = data['sender'];
      final type = data['type'];
      final payload = data['data'];

      if (sender == id) return;

      switch (type) {
        case 'offer':
          _handleOffer(sender, payload);
          break;
        case 'answer':
          _handleAnswer(sender, payload);
          break;
        case 'candidate':
          _handleCandidate(sender, payload);
          break;
        case 'user_joined':
          _createPeerConnection(sender);
          break;
        case 'user_left':
          _removePeer(sender);
          break;
      }
    });
  }

  Future<void> _createPeerConnection(String peerId) async {
    if (_peerConnections.containsKey(peerId)) return;

    final pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // Добавьте свои TURN-серверы при необходимости
      ],
    });

    pc.onIceCandidate = (candidate) {
      _channel.sink.add(json.encode({
        'type': 'candidate',
        'data': {
          'candidate': candidate.candidate,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdpMid': candidate.sdpMid,
        },
      }));
    };

    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        setState(() {
          _remoteRenderers[peerId] = RTCVideoRenderer();
          _remoteRenderers[peerId]!.initialize().then((_) {
            _remoteRenderers[peerId]!.srcObject = event.streams[0];
          });
        });
      }
    };

    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _removePeer(peerId);
      }
    };

    _peerConnections[peerId] = pc;

    // Добавляем локальные треки в соединение
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    // Если мы инициируем соединение, создаем offer
    if (peerId.compareTo(id.toString()) > 0) {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _channel.sink.add(json.encode({
        'type': 'offer',
        'data': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
      }));
    }
  }

  Future<void> _handleOffer(String peerId, dynamic offer) async {
    await _createPeerConnection(peerId);
    final pc = _peerConnections[peerId]!;
    await pc.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
    
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    
    _channel.sink.add(json.encode({
      'type': 'answer',
      'data': {
        'sdp': answer.sdp,
        'type': answer.type,
      },
    }));
  }

  Future<void> _handleAnswer(String peerId, dynamic answer) async {
    final pc = _peerConnections[peerId]!;
    await pc.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
  }

  Future<void> _handleCandidate(String peerId, dynamic candidate) async {
    final pc = _peerConnections[peerId]!;
    await pc.addCandidate(RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    ));
  }

  void _removePeer(String peerId) {
    if (_peerConnections.containsKey(peerId)) {
      _peerConnections[peerId]!.close();
      _peerConnections.remove(peerId);
    }
    if (_remoteRenderers.containsKey(peerId)) {
      _remoteRenderers[peerId]!.dispose();
      _remoteRenderers.remove(peerId);
    }
    setState(() {});
  }

  void _toggleMute() {
    if (_localStream == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  void _toggleVideo() {
    if (_localStream == null) return;
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _localStream!.getVideoTracks().forEach((track) {
      track.enabled = !_isVideoOff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Групповой видеочат - Комната ${widget.team.id}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: _remoteRenderers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _localRenderer.srcObject != null
                            ? RTCVideoView(_localRenderer)
                            : Center(child: CircularProgressIndicator()),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          color: Colors.black54,
                          child: Text(
                            'Вы ($id)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  final peerId = _remoteRenderers.keys.elementAt(index - 1);
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _remoteRenderers[peerId]!.srcObject != null
                            ? RTCVideoView(_remoteRenderers[peerId]!)
                            : Center(child: CircularProgressIndicator()),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          color: Colors.black54,
                          child: Text(
                            peerId,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  color: _isMuted ? Colors.red : Colors.white,
                  onPressed: _toggleMute,
                ),
                IconButton(
                  icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
                  color: _isVideoOff ? Colors.red : Colors.white,
                  onPressed: _toggleVideo,
                ),
                IconButton(
                  icon: Icon(Icons.call_end),
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _localRenderer.dispose();
    _peerConnections.values.forEach((pc) => pc.close());
    _remoteRenderers.values.forEach((renderer) => renderer.dispose());
    _channel.sink.close();
    super.dispose();
  }
}