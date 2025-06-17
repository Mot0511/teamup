import 'package:flutter/material.dart';

final textBase = TextStyle(color: Colors.white);

final textTheme = TextTheme(
  titleMedium: textBase.copyWith(fontSize: 18),
  labelSmall: textBase.copyWith(fontSize: 10),
  headlineMedium: textBase.copyWith(fontSize: 28),
);

final theme = ThemeData(
  primaryColor: Color(0xff016335),
  scaffoldBackgroundColor: Color(0xff1A1A1A),
  textTheme: textTheme,
  cardColor: Color.fromARGB(255, 36, 35, 35)
);