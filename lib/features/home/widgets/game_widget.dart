import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class GameWidget extends StatefulWidget {
  const GameWidget({super.key, this.game, this.onTap});
  final Game? game;
  final GestureTapCallback? onTap;

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  ImageProvider? cover;

  final searchRepository = GetIt.I<SearchRepository>();

  @override
  void initState() {
    super.initState();
    loadCover();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    loadCover();
  }

  Future<void> loadCover() async {
    if (widget.game == null) return;
    cover = await searchRepository.getGameCover(widget.game!.id);
    if (mounted) {
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 80,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: BorderRadius.circular(10)
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: widget.game == null
            ? Align(
              alignment: Alignment.center,
              child: Text('Нажмите, чтобы выбрать игру', style: theme.textTheme.labelMedium),
            )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: cover != null
                      ? Container(
                        height: 80,
                        decoration: BoxDecoration(
                          image: DecorationImage(image: cover!, fit: BoxFit.cover),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10))
                        ),
                      )
                      : ShimmerWidget(width: 150, height: 80),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.game!.name, style: theme.textTheme.labelMedium),
                        if (widget.onTap != null)
                        Text(
                          'Нажмите, чтобы выбрать игру', 
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ],
                    ),
                  )
                ],
              ),
        ),
      )
    );
  }
}