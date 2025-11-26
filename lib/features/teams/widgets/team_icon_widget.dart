import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/user/user_repository.dart';

class TeamIconWidget extends StatelessWidget {
  TeamIconWidget({super.key, required this.id, this.size=150, this.image});
  final int id;
  final double size;
  final ImageProvider? image;

  final teamsRepository = GetIt.I<TeamsRepository>();

  @override
  Widget build(BuildContext context) {
    return image != null
      ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: (image as ImageProvider),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(size / 2)
            )
          )
      : FutureBuilder(
        future: teamsRepository.getIcon(id),
        builder: (context, AsyncSnapshot snap) {
          if (snap.hasData) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: snap.data,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(size / 2)
              )
            );
          } else {
            return Shimmer.fromColors(
              baseColor: const Color.fromARGB(255, 48, 48, 48),
              highlightColor: const Color.fromARGB(255, 66, 66, 66),
              period: Duration(milliseconds: 500),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(150),
                  color: const Color.fromARGB(255, 0, 255, 42)
                ),
              ),
            );
          }
        }
      );
  }
}