import 'package:flutter/material.dart';

class BoxButton extends StatelessWidget {
  const BoxButton({super.key, required this.title, required this.body, required this.isActive, required this.onTap});
  final String title;
  final String body;
  final bool isActive;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 1, color: isActive ? Colors.white : const Color.fromARGB(255, 175, 175, 175))
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(color: isActive ? Colors.white : const Color.fromARGB(255, 175, 175, 175))),
                  Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: isActive ? Colors.white : const Color.fromARGB(255, 175, 175, 175))),
                ],
              ),
            )
          ),
        )
      ],
    );
  }
}