import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SihmmerWidget extends StatelessWidget {
  const SihmmerWidget({super.key, this.width = double.infinity, this.height = 50, this.radius = 10});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color.fromARGB(255, 48, 48, 48),
      highlightColor: const Color.fromARGB(255, 66, 66, 66),
      period: Duration(milliseconds: 500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: const Color.fromARGB(255, 0, 255, 42)
        ),
      ),
    );
  }
}