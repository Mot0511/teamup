import 'package:flutter/material.dart';

class NotificationWidget extends StatelessWidget {
  const NotificationWidget({super.key, this.icon, required this.title, required this.body});
  final ImageProvider? icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 75,
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.canvasColor,
        borderRadius: BorderRadius.circular(10)
      ),
      child: Ink(
        child: InkWell(
          onTap: () {},
          child: Row(
            children: [
              if (icon != null)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  image: DecorationImage(image: icon!, fit: BoxFit.cover),
                  borderRadius: BorderRadius.circular(50)
                ),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(body, style: theme.textTheme.bodyLarge),
                ],
              )
            ],
          ),
        ),
      )
    );
  }
}