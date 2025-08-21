import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SignalingService {
  final String wsUrl, roomId, selfId;
  final void Function(List<String>) onPeersChanged;
  late WebSocketChannel _ws;
  MediaStream? _local;
  final Map<String, RTCPeerConnection> _pcs = {};

  List<String> get peers => _pcs.keys.toList();

  SignalingService({required this.wsUrl, required this.roomId, required this.selfId, required this.onPeersChanged});

  Future<void> init() async {
    _local = await navigator.mediaDevices.getUserMedia({"audio": true, "video": false});
    _ws = WebSocketChannel.connect(Uri.parse(wsUrl));
    _ws.stream.listen(_onMessage);
    _send({"type": "join", "roomId": roomId, "peerId": selfId});
  }

  void dispose() => leave();

  Future<void> leave() async {
    _send({"type": "leave"});
    for (final pc in _pcs.values) { await pc.close(); }
    _pcs.clear();
    await _local?.dispose();
    _local = null;
    onPeersChanged(peers);
    await _ws.sink.close();
  }

  void _send(Map<String,dynamic> m) => _ws.sink.add(jsonEncode(m));

  Future<void> _createPc(String peerId, {bool offer = false}) async {
    final pc = await createPeerConnection({"iceServers": [{"urls": "stun:stun.l.google.com:19302"}]});
    _pcs[peerId] = pc;
    _local?.getTracks().forEach((t) async => await pc.addTrack(t, _local!));
    pc.onIceCandidate = (c) { if (c != null) _send({"type":"candidate","to":peerId,"candidate":c.toMap()}); };
    pc.onTrack = (e) { /* audio auto plays */ };
    if (offer) {
      final offerSdp = await pc.createOffer();
      await pc.setLocalDescription(offerSdp);
      _send({"type":"offer","to":peerId,"sdp":offerSdp.sdp});
    }
  }

  void _onMessage(dynamic data) async {
    final msg = jsonDecode(data);
    switch (msg["type"]) {
      case "peers":
        for (final p in msg["peers"]) { await _createPc(p, offer: true); }
        break;
      case "peer-joined":
        await _createPc(msg["peerId"]);
        break;
      case "offer":
        final pc = await createPeerConnection({"iceServers":[{"urls":"stun:stun.l.google.com:19302"}]});
        _pcs[msg["from"]] = pc;
        _local?.getTracks().forEach((t) async => await pc.addTrack(t, _local!));
        pc.onIceCandidate = (c){ if(c!=null) _send({"type":"candidate","to":msg["from"],"candidate":c.toMap()}); };
        await pc.setRemoteDescription(RTCSessionDescription(msg["sdp"], "offer"));
        final ans = await pc.createAnswer();
        await pc.setLocalDescription(ans);
        _send({"type":"answer","to":msg["from"],"sdp":ans.sdp});
        break;
      case "answer":
        await _pcs[msg["from"]]?.setRemoteDescription(RTCSessionDescription(msg["sdp"], "answer"));
        break;
      case "candidate":
        final cand = RTCIceCandidate(msg["candidate"]["candidate"], msg["candidate"]["sdpMid"], msg["candidate"]["sdpMLineIndex"]);
        await _pcs[msg["from"]]?.addCandidate(cand);
        break;
      case "peer-left":
        await _pcs[msg["peerId"]]?.close();
        _pcs.remove(msg["peerId"]);
        onPeersChanged(peers);
        break;
    }
    onPeersChanged(peers);
  }
}