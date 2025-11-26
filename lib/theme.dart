import 'package:flutter/material.dart';

final textBase = TextStyle(color: Colors.white);

final textTheme = TextTheme(
  displayMedium: textBase.copyWith(fontSize: 35),
  titleLarge: textBase.copyWith(fontSize: 24),
  titleMedium: textBase.copyWith(fontSize: 18),
  labelLarge: textBase.copyWith(fontSize: 20),
  labelMedium: textBase.copyWith(fontSize: 18),
  labelSmall: textBase.copyWith(fontSize: 13),
  headlineLarge: textBase.copyWith(fontSize: 35),
  headlineMedium: textBase.copyWith(fontSize: 28),
);

final ColorScheme colorScheme = const ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xff016335),
  onPrimary: Colors.black, 
  secondary: Color(0xFF00838F),
  onSecondary: Colors.white, 
  error: Color.fromARGB(255, 153, 10, 0), 
  onError: Color.fromARGB(255, 0, 0, 0), 
  surface: Color(0xff016335),
  onSurface: Color.fromARGB(255, 255, 255, 255),
);

final theme = ThemeData(
  primaryColor: Color(0xff016335),
  colorScheme: colorScheme,
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xff1A1A1A),
    titleTextStyle: textBase.copyWith(fontSize: 24),
    iconTheme: const IconThemeData(
      color: Colors.white,
    )
  ),
  scaffoldBackgroundColor: Color(0xff1A1A1A),
  textTheme: textTheme,
  cardColor: Color.fromARGB(255, 36, 35, 35),
  canvasColor: const Color.fromARGB(255, 36, 35, 35),

);