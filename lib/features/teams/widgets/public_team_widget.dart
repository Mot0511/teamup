import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/teams/utils/get_members_count_string.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class PublicTeamWidget extends StatefulWidget {
  const PublicTeamWidget({super.key, required this.team});
  final Team team;

  @override
  State<PublicTeamWidget> createState() => _PublicTeamWidgetState();
}

class _PublicTeamWidgetState extends State<PublicTeamWidget> {
  ImageProvider? cover;

  final searchRepository = GetIt.I<SearchRepository>();

  @override
  void initState() {
    super.initState();
    loadGameCover();
  }

  Future<void> loadGameCover() async {
    if (widget.team.game == null) return;
    cover = await searchRepository.getGameCover(widget.team.game!.id);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.canvasColor,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TeamView(team: widget.team))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cover != null)
            Container(
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(image: cover!, fit: BoxFit.cover, alignment: Alignment.center),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.team.name, style: theme.textTheme.titleLarge),
                  Text('${getMembersCountString(widget.team.users.length)} ${widget.team.game != null ? '| ${widget.team.game!.name}' : ''}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                ],
              )
            )
          ],
        ),
      )
    );
  }
}