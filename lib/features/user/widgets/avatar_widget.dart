import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:teamup/features/user/user.dart';

class AvatarWidget extends StatelessWidget {
  AvatarWidget({super.key, required this.uid, this.size=150, this.image, this.onTap});
  final String uid;
  final double size;
  final ImageProvider? image;
  final GestureTapCallback? onTap;

  final userRepository = GetIt.I<UserRepository>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: userRepository.getAvatar(uid),
      builder: (context, AsyncSnapshot snap) {
        if (snap.hasData) {
          return Container(
            width: size,
            height: size,
            alignment: Alignment.bottomRight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: snap.data,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(size / 2)
            ),
            child: onTap != null
              ? CircleAvatar(
                radius: size / 6,
                backgroundColor: theme.primaryColor,
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: onTap,
                ),
              )
              : null
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