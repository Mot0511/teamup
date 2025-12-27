import 'package:flutter/material.dart';

class OutlinedField extends StatelessWidget {
  const OutlinedField({
    super.key,
    required this.controller,
    required this.hint,
    this.error,
    this.type=TextInputType.text,
    this.obscureText = false,
  });

  final String hint;
  final TextEditingController controller;
  final TextInputType type;
  final String? error;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xff434343), width: 1)
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Color(0xff636363), fontSize: 15, fontWeight: FontWeight.normal),
            fillColor: Color(0xff434343),
            filled: true
          ),
          style: theme.textTheme.labelMedium,
          keyboardType: type,
          obscureText: obscureText
        ),
        SizedBox(height: 5),
        if (error != null)
        Text(error!, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error)),
        SizedBox(height: 10),
      ],
    );
  }
}