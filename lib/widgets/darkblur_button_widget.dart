import 'dart:ui';

import 'package:flutter/material.dart';

class DarkButtonWidget extends StatelessWidget {
  const DarkButtonWidget({super.key, this.width=60, this.height=60, required this.onTap, required this.child});
  final double width;
  final double height;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: const Color.fromRGBO(36, 35, 35, 0.8),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: child
            ),
          ),
        )
      ),
    );
  }
}