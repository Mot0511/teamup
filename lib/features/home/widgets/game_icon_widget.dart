import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class GameIcon extends StatefulWidget {
  const GameIcon({super.key, required this.game});
  final Game? game;

  @override
  State<GameIcon> createState() => _GameIconState();
}

class _GameIconState extends State<GameIcon> {

  ImageProvider? icon;

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
    icon = await searchRepository.getGameIcon(widget.game!.id);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          image: DecorationImage(image: icon!, fit: BoxFit.cover),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return ShimmerWidget(
      width: 20,
      height: 20,
      radius: 2,
    );
  }
}