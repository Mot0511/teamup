import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = GetIt.I<SupabaseClient>();
  final analyticsRepository = GetIt.I<AnalyticsRepository>();
  final voiceService = GetIt.I<VoiceService>();

  List<String> peers = [];

  @override
  void initState() {
    super.initState();
    analyticsRepository.logEvent('open_team_screen');

    if (voiceService.room != null) {
      if (voiceService.roomID == widget.team.id) {
        isVoiceOn = voiceService.isVoiceOn;
        isSoundOn = voiceService.isSoundOn;
      } else {
        isSoundOn = false;
      }
      setState(() {});
    } else {
      join(false, true);
    }
  }
 
  Future<void> join(bool isVoiceOn, bool isSoundOn) async {
    final uid = supabase.auth.currentUser!.id;
    voiceService.onPeersChanged = (List<String> peers) => setState(() => this.peers = peers);
    await voiceService.connect(
      uid,
      widget.team.id,
      isVoiceOn,
      isSoundOn,
    );
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void onToggleVoice() async {
    if (voiceService.room == null || voiceService.roomID != widget.team.id) {
      await voiceService.disconnect();
      await join(true, false);
    } else {
      await voiceService.setIsVoiceOn(!isVoiceOn);
    }
    isVoiceOn = !isVoiceOn;
    setState(() {});
  }

  void onToggleSound() async {
    if (voiceService.room == null || voiceService.roomID != widget.team.id) {
      await voiceService.disconnect();
      await join(false, true);
    } else {
      await voiceService.setIsSoundOn(!isSoundOn);
    }
    isSoundOn = !isSoundOn;
    setState(() {});
  }

  @override
  void dispose() {
    if (!isSoundOn && !isVoiceOn) {
      voiceService.disconnect();
    }
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
                title: Row(
                  children: [
                    Expanded(child: Text(
                      widget.team.name, 
                      style: theme.textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                    SizedBox(width: 5),
                    if (voiceService.roomID == widget.team.id)
                    Stack(
                      children: List.generate(voiceService.peers.length, (i) {
                        return Padding(
                          padding: EdgeInsets.only(left: 5.0 * i),
                          child: AvatarWidget(uid: voiceService.peers[i], size: 20)
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
                  onPressed: () => onToggleVoice(),
                  icon: isVoiceOn ? Icon(Icons.mic, color: Colors.green) : Icon(Icons.mic_off, color: Colors.red)
                ),
                IconButton(
                  onPressed: () => onToggleSound(),
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