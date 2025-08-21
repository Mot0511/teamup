import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/chats/widgets/messenger_widget.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/views/create_team_view.dart';
import 'package:teamup/features/teams/signaling_service2.dart';
import 'package:teamup/features/teams/widgets/team_icon_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';

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
  SignalingService? signalingService;
  
  final List<RTCVideoRenderer> remoteRTCVideoRenderers = [];

  final List<User> onlineUsers = [];

  @override
  void initState() {
    super.initState();

    final uid = (userBloc.state as UserStateLoaded).user.uid;

    signalingService = SignalingService(
      websocketUrl: 'http://192.168.0.75:9000',
      uid: uid
    );
    setState(() {});

    signalingService?.onRemoteStreams = (streams) async {
      for (MediaStream stream in streams) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = stream;
        remoteRTCVideoRenderers.add(renderer);
        setState(() {});
      }
    };

    signalingService?.onNewConnection = (userID) {
      onlineUsers.add(widget.team.users.where((user) => user.uid == userID).toList()[0]);
      setState(() {});
    };

    signalingService?.setupPeerConnection(widget.team.id);
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    signalingService?.dispose();
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
              titleSpacing: 0.0,
              title: ListTile(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTeamView(team: widget.team)));
                  setState(() {});
                },
                leading: TeamIconWidget(id: widget.team.id, size: 50),
                title: Text(
                  widget.team.name, 
                  style: theme.textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${widget.team.users.length} участников', 
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
            body: MessengerWidget(chat: widget.team)
          );
        } else {
          return Scaffold();
        }
      }
    );
  }
}