import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';

class SignalingService {
  Socket? socket;

  final Map<String, RTCPeerConnection> peerConnections = {};

  Function? onLocalStream;
  Function? onRemoteStreams;
  Function? onNewConnection;

  List<RTCIceCandidate> iceCandidates = [];

  String? userID;
  int? teamID;

  final player = AudioPlayer();

  final config = {
      'sdpSemantics': 'unified-plan',
      "iceServers": [
        {
          "urls": "stun:stun.relay.metered.ca:80",
        },
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

  SignalingService({required String websocketUrl, required String uid}) {
    userID = uid;
    socket = io(websocketUrl, {
      'transports': ['websocket'],
      'query': {'callerID': uid}
    });

    socket!.onConnect((data) {
      print('Socket connected!');
    });

    socket!.onConnect((error) {
      print('Connect Error: $error');
    });

    socket!.connect();
  }

  void sendIceCandidates(String from, String to) {
    for (RTCIceCandidate candidate in iceCandidates) {
      socket!.emit("IceCandidate", {
        "from": from,
        "to": to,
        "room": teamID,
        "iceCandidate": {
          "id": candidate.sdpMid,
          "label": candidate.sdpMLineIndex,
          "candidate": candidate.candidate
        }
      });
    }
  }

  Future<RTCPeerConnection> getPeerConnection() async {
    final RTCPeerConnection pc = await createPeerConnection(config);
    final localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true
    });

    localStream.getTracks().forEach((track) {
      pc.addTrack(track, localStream);
    });

    setPCListenings(pc);

    return pc;
  }

  void setupPeerConnection(int teamID) async {
    this.teamID = teamID;
    listenSocket();
    socket!.emit('join', {
      'room': teamID,
      'user': userID,
    });

    final RTCPeerConnection pc = await createPeerConnection(config);
    RTCSessionDescription offer = await pc.createOffer();
    socket!.emit('offer', {
      "room": teamID,
      "callerID": userID,
      "sdpOffer": offer.toMap(),
    });

  }

  void setPCListenings(RTCPeerConnection pc) {
    pc.onTrack = (event) async {
      onRemoteStreams!(event.streams);
    };

    pc.onIceCandidate = (RTCIceCandidate iceCandidate) => iceCandidates.add(iceCandidate);
  
    pc.onConnectionState = (state) async {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        await player.setAsset('assets/audio/connected.mp3');
        player.play();
      }
    };
  }

  void listenSocket() {
    socket!.on("answer", (data) async {
      final from = data['from'];
      if (from != userID) {
        
        final RTCPeerConnection pc = await getPeerConnection();
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        await pc.setRemoteDescription(
          RTCSessionDescription(
            data["sdpAnswer"]["sdp"],
            data["sdpAnswer"]["type"],
          ),
        );

        peerConnections[from] = pc;
        sendIceCandidates(userID!, from);
        onNewConnection!(from);
      }
    });

    socket!.on("IceCandidate", (data) {
      final from = data['from'];
      final to = data['to'];
      if (from == userID) return;
      if (to != userID) return;
      final String candidate = data["iceCandidate"]["candidate"];
      final String sdpMid = data["iceCandidate"]["id"];
      final int sdpMLineIndex = data["iceCandidate"]["label"];
      
      // add iceCandidate
      peerConnections[from]?.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      }
    );

    socket!.on('offer', (data) async {
      if (data['callerID'] == userID) return;
      final offer = data['sdpOffer'];
      final callerID = data['callerID'];

      final RTCPeerConnection pc = await getPeerConnection();

      await pc.setRemoteDescription(
        RTCSessionDescription(offer["sdp"], offer["type"]),
      );

      // create SDP answer
      RTCSessionDescription answer = await pc.createAnswer();

      // set SDP answer as localDescription for peerConnection
      pc.setLocalDescription(answer);

      peerConnections[callerID] = pc;
      
      socket!.emit("answer", {
        "room": teamID,
        "from": userID,
        "sdpAnswer": answer.toMap(),
      });
      
      sendIceCandidates(userID!, callerID);
    });

    socket!.on('leave', (data) {
      peerConnections.remove(data['user']);
    });
  }

  void dispose() {
      for (RTCPeerConnection pc in peerConnections.values) {
        pc.dispose();
      }
      peerConnections.clear();
      socket!.emit('leave', {
        'user': userID,
        'room': teamID
      });
    }
}