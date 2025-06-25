import 'package:flutter/material.dart';

class GlobalProvider extends ChangeNotifier {
  bool? isLogined;

  set setIsLogined(bool state) {
    isLogined = state;
    notifyListeners();
  }

  GlobalProvider();
}
