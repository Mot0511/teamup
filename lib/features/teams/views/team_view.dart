import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
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

  bool isVoice = false;
  bool isSound = true;

  final userBloc = GetIt.I<UserBloc>();
  final voiceService = GetIt.I<VoiceService>();

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
                  onPressed: () => setState(() => isVoice = !isVoice),
                  icon: isVoice ? Icon(Icons.mic, color: Colors.green) : Icon(Icons.mic_off, color: Colors.red)
                ),
                IconButton(
                  onPressed: () => setState(() => isSound = !isSound),
                    icon: isSound ? Icon(Icons.volume_up, color: Colors.green) : Icon(Icons.volume_off, color: Colors.red)
                  ),
              ],
            ),
          );
        } else {
          return Scaffold();
        }
      }
    );
  }
}