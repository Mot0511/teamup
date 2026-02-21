import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';

class TeamWidget extends StatefulWidget {
  TeamWidget({super.key, required this.team});
  final Team team;

  @override
  State<TeamWidget> createState() => _TeamWidgetState();
}

class _TeamWidgetState extends State<TeamWidget> {
  Offset? tapPosition;

  final teamsBloc = GetIt.I<TeamsBloc>();
  final userBloc = GetIt.I<UserBloc>();


  void removeTeam() {
    if (userBloc.state is UserStateLoaded) {
      teamsBloc.add(RemoveTeam(team: widget.team, uid: (userBloc.state as UserStateLoaded).user.uid));
    }
  }

  void showContextMenu(context) async {
    if (tapPosition == null) return;
    final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    final theme = Theme.of(context);

    final result = await showMenu(  
      color: theme.cardColor,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition!.dx, tapPosition!.dy, 30, 30), 
        Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                overlay.paintBounds.size.height)),
      context: context, 
      items: [
        PopupMenuItem(child: Text('Выйти из команды', style: theme.textTheme.labelSmall), value: 'removeChat')
      ]
    );

    if (result == 'removeChat') removeTeam();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(widget.team.id.toString()), 
      background: Container(color: theme.colorScheme.error),
      onDismissed: (direction) => removeTeam(),
      child: GestureDetector(
        onTapDown: (details) => setState(() => tapPosition = details.globalPosition),
        onLongPress: () => showContextMenu(context),
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamView(team: widget.team))),
          leading: TeamIconWidget(id: widget.team.id, size: 50),
          title: Text(widget.team.name, style: theme.textTheme.labelMedium),
          subtitle: widget.team.game != null ? Text(widget.team.game!.name, style: theme.textTheme.labelSmall) : null,
        ),
      )
    );
  }
}