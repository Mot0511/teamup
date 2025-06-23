import 'package:flutter/material.dart';

class Field extends StatelessWidget {
  const Field({
    super.key, 
    required this.title, 
    required this.controller, 
    this.type=TextInputType.text,
    this.maxLines=1
  });
  final String title;
  final TextEditingController controller;
  final TextInputType type;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
          ),
          style: theme.textTheme.labelMedium,
          keyboardType: type,
          maxLines: maxLines
        ),
        SizedBox(height: 20),
      ],
    );
  }
}