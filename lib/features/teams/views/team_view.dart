import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:teamup/features/chats/widgets/messenger_widget.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/views/create_team_view.dart';
import 'package:teamup/features/teams/voice_service.dart';
import 'package:teamup/features/teams/voice_provider.dart';
import 'package:teamup/features/teams/widgets/team_icon_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';
import 'package:teamup/features/analytics/repositories/analytics_repository.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key, required this.team});
  final Team team;

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {

  bool isVoiceOn = false;
  bool isSoundOn = true;

  final userBloc = GetIt.I<UserBloc>();
  final analyticsRepository = GetIt.I<AnalyticsRepository>();

  VoiceService? voiceService;
  
  @override
  void initState() {
    super.initState();
    analyticsRepository.logEvent('open_team_screen');
    final voiceProvider = Provider.of<VoiceProvider>(context, listen: false);
    voiceService = voiceProvider.voiceService;
    if (voiceProvider.voiceService != null) {
      if (voiceProvider.voiceService!.roomId == widget.team.id.toString()) {
        isVoiceOn = voiceProvider.isVoiceOn;
        isSoundOn = voiceProvider.isSoundOn;
      } else {
        isSoundOn = false;
      }
      setState(() {});
    } else {
      join(voiceProvider, false, true);
    }
  }
 
  Future<void> join(VoiceProvider voiceProvider, bool isVoiceOn, bool isSoundOn) async {
    final user = (userBloc.state as UserStateLoaded).user;
    await voiceProvider.init(      
      roomId: widget.team.id.toString(),
      selfId: user.uid,
      isVoiceOn: isVoiceOn,
      isSoundOn: isSoundOn,
    );
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void onToggleVoice(VoiceProvider voiceProvider) async {
    if (voiceProvider.voiceService == null || voiceProvider.voiceService!.roomId != widget.team.id.toString()) {
      voiceProvider.voiceService?.dispose();
      await join(voiceProvider, true, false);
    } else {
      await voiceProvider.toggleVoice();
    }
    isVoiceOn = !isVoiceOn;
    setState(() {});
  }

  void onToggleSound(VoiceProvider voiceProvider) async {
    if (voiceProvider.voiceService == null || voiceProvider.voiceService!.roomId != widget.team.id.toString()) {
      voiceProvider.voiceService?.dispose();
      await join(voiceProvider, false, true);
    } else {
      await voiceProvider.toggleSound();
    }
    isSoundOn = !isSoundOn;
    setState(() {});
  }

  @override
  void dispose() {
    if (!isSoundOn && !isVoiceOn) {
      voiceService?.dispose();
      voiceService = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceProvider = Provider.of<VoiceProvider>(context);
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
                title: Row(
                  children: [
                    Text(
                      widget.team.name, 
                      style: theme.textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(width: 5),
                    if (voiceProvider.voiceService?.roomId == widget.team.id.toString())
                    Stack(
                      children: List.generate(voiceProvider.peers.length, (i) {
                        return Padding(
                          padding: EdgeInsets.only(left: 5.0 * i),
                          child: AvatarWidget(uid: voiceProvider.peers[i], size: 20)
                        );
                      })
                    )
                  ],
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
                  onPressed: () => onToggleVoice(voiceProvider),
                  icon: isVoiceOn ? Icon(Icons.mic, color: Colors.green) : Icon(Icons.mic_off, color: Colors.red)
                ),
                IconButton(
                  onPressed: () => onToggleSound(voiceProvider),
                  icon: isSoundOn ? Icon(Icons.volume_up, color: Colors.green) : Icon(Icons.volume_off, color: Colors.red)
                ),
              ],
            ),
            body: MessengerWidget(chat: widget.team)
          );
        } else if (state is UserStateError) {
          return Center(child: Text('Ошибка при загурзке данных пользователя'));
        }
        return Scaffold();
      }
    );
  }
}