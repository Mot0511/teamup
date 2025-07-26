import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/views/create_team_view.dart';
import 'package:teamup/features/teams/voice_service.dart';
import 'package:teamup/features/teams/widgets/team_icon_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key, required this.team});
  final Team team;

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {

  bool isVoiceOn = true;
  bool isSoundOn = true;

  final userBloc = GetIt.I<UserBloc>();
  
  final socket = VoiceService.instance.socket;

  final localRTCVideoRenderer = RTCVideoRenderer();
  List<RTCVideoRenderer> remoteRTCVideoRenderers = [];

  MediaStream? localStream;
  Map<String, RTCPeerConnection> rtcPeerConnections = {};
  List<RTCIceCandidate> rtcIceCandidates = [];

  @override
  void initState() {
    super.initState();
    // initializing renderers 
    localRTCVideoRenderer.initialize();
    // setup Peer Connection
    setupPeerConnection();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  setupPeerConnection() async {
    final uid = (userBloc.state as UserStateLoaded).user.uid;
    socket!.emit('join', {
      'room': widget.team.id,
      'user': uid,
    });

    // when call is accepted by remote peer
    socket!.on("callAnswered", (data) async {
      final callerID = data['callerID'];
      if (callerID == uid) {
        
        await rtcPeerConnections[callerID]?.setRemoteDescription(
          RTCSessionDescription(
            data["sdpAnswer"]["sdp"],
            data["sdpAnswer"]["type"],
          ),
        );

        // send iceCandidate generated to remote peer over signalling
        for (RTCIceCandidate candidate in rtcIceCandidates) {
          socket!.emit("IceCandidate", {
            "callerID": callerID,
            "room": widget.team.id,
            "iceCandidate": {
              "id": candidate.sdpMid,
              "label": candidate.sdpMLineIndex,
              "candidate": candidate.candidate
            }
          });
        }
        rtcIceCandidates.clear();
      }
    });

    final rtcPeerConnection = await getPeerConnection();
    RTCSessionDescription offer = await rtcPeerConnection.createOffer({
      'mandatory': {
        'OfferToReceiveVideo': true,
        'OfferToReceiveAudio': true,
      },
      'optional': [
        {'googImprovedWifiBwe': true},
        {'googScreencastMinBitrate': 30000.0},
      ],
    });

    // set SDP offer as localDescription for peerConnection
    await rtcPeerConnection.setLocalDescription(offer);

    rtcPeerConnections[uid] = rtcPeerConnection;
    setState(() {});

    // make a call to remote peer over signalling
    socket!.emit('makeCall', {
      "room": widget.team.id,
      "callerID": uid,
      "sdpOffer": offer.toMap(),
    });

    // listen for Remote IceCandidate
    socket!.on("IceCandidate", (data) {
      final callerID = data['callerID'];
      if (callerID == uid) return;
      final String candidate = data["iceCandidate"]["candidate"];
      final String sdpMid = data["iceCandidate"]["id"];
      final int sdpMLineIndex = data["iceCandidate"]["label"];

      // add iceCandidate
      rtcPeerConnections[callerID]?.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      }
    );

    socket!.on('newCall', (data) async {
      if (data['callerID'] == uid) return;
      final offer = data['sdpOffer'];
      final callerID = data['callerID'];

      final rtcPeerConnection = await getPeerConnection();
      await rtcPeerConnection.setRemoteDescription(
        RTCSessionDescription(offer["sdp"], offer["type"]),
      );

      // create SDP answer
      RTCSessionDescription answer = await rtcPeerConnection.createAnswer();

      // set SDP answer as localDescription for peerConnection
      rtcPeerConnection.setLocalDescription(answer);

      rtcPeerConnections[callerID] = rtcPeerConnection;
      setState(() {});

      // send SDP answer to remote peer over signalling
      socket!.emit("answerCall", {
        "room": widget.team.id,
        "callerID": callerID,
        "sdpAnswer": answer.toMap(),
      });
    });
  }

  Future<RTCPeerConnection> getPeerConnection() async {
    final rtcPeerConnection = await createPeerConnection({
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
      'codecs': {
        'video': ['VP8', 'H264'], // Явно указываем предпочтительные кодеки
        'audio': ['opus']
      }
    });

    // listen for remotePeer mediaTrack event
    rtcPeerConnection.onTrack = (event) async {
      if (event.track.kind != 'video') return;
      for (var stream in event.streams) {
        await Future.doWhile(() async {
          await Future.delayed(Duration(milliseconds: 100));
          return stream.getVideoTracks().isEmpty;
        }).timeout(Duration(seconds: 5));
      
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        event.track.onEnded = () {
          print('Video track ended');
          renderer.srcObject = null;
        };
        renderer.srcObject = stream;
        renderer.onFirstFrameRendered = () {
          print('Получен перывй кадр');
        };
        remoteRTCVideoRenderers.add(renderer);
        setState(() {});
      }
    };

    final micStatus = await Permission.microphone.request();
    final cameraStatus = await Permission.camera.request();
    if (!micStatus.isGranted || !cameraStatus.isGranted) {
      throw Exception("Разрешения не получены!");
    }
    // get localStream
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true
    });
    // add mediaTrack to peerConnection
    localStream!.getTracks().forEach((track) {
      rtcPeerConnection.addTrack(track, localStream!);
    });

    localRTCVideoRenderer.srcObject = localStream;
    setState(() {});

    // listen for local iceCandidate and add it to the list of IceCandidate
    rtcPeerConnection.onIceCandidate = 
        (RTCIceCandidate candidate) => rtcIceCandidates.add(candidate);

    rtcPeerConnection.onIceConnectionState = (state) {
      print('ICE connection state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        print('ICE connection failed');
      }
    };

    return rtcPeerConnection;
  }

  leaveCall() {
    Navigator.pop(context);
  }

  toggleMic() {
    // change status
    isVoiceOn = !isVoiceOn;
    isSoundOn = !isSoundOn;
    // enable or disable audio track
    localStream?.getAudioTracks().forEach((track) {
      track.enabled = isSoundOn;
    });
    setState(() {});
  }

  @override
  void dispose() {
    localRTCVideoRenderer.dispose();
    for (RTCVideoRenderer renderer in remoteRTCVideoRenderers!) {
      renderer.dispose();
    }
    localStream?.dispose();
    for (RTCPeerConnection peerConnection in rtcPeerConnections.values) {
      peerConnection.dispose();
    }
    socket!.emit('leave', {
      'user': (userBloc.state as UserStateLoaded).user.uid,
      'room': widget.team.id
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) {
        if (state is UserStateLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTeamView(team: widget.team))),
                leading: TeamIconWidget(id: widget.team.id, size: 50),
                title: Text(widget.team.name, style: theme.textTheme.labelMedium),
                subtitle: Text('${widget.team.users.length} участников', style: theme.textTheme.labelSmall),
              ),
              actions: [
                IconButton(
                  onPressed: () => setState(() => isVoiceOn = !isVoiceOn),
                  icon: isVoiceOn ? Icon(Icons.mic, color: Colors.green) : Icon(Icons.mic_off, color: Colors.red)
                ),
                IconButton(
                  onPressed: () => setState(() => isSoundOn = !isSoundOn),
                    icon: isSoundOn ? Icon(Icons.volume_up, color: Colors.green) : Icon(Icons.volume_off, color: Colors.red)
                  ),
              ],
            ),
            body: Column(
              children: remoteRTCVideoRenderers.isNotEmpty
                ? remoteRTCVideoRenderers.map((renderer) => 
                  Expanded(child: RTCVideoView(renderer))
                ).toList()
                : [Text("remoteRTCVideoRenderers is empty")]
            )
            
          );
        } else {
          return Scaffold();
        }
      }
    );
  }
}