import 'package:flutter/material.dart';

class SocialProviderWidget extends StatelessWidget {
  const SocialProviderWidget({super.key, required this.provider, required this.onClick});
  final String provider;
  final GestureTapCallback onClick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Ink(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
          image: DecorationImage(image: AssetImage('assets/images/$provider.png'))
        ),
        child: InkWell(
          onTap: onClick,
          customBorder: CircleBorder(),
        ),
      ),
    );
  }
}