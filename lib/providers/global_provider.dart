import 'package:flutter/material.dart';

class GlobalProvider extends ChangeNotifier {

  bool? _isLogined;
  bool? get isLogined => _isLogined;
  set isLogined(bool? state) {
    _isLogined = state;
    notifyListeners();
  }

  int _currentPage = 0;
  int get currentPage => _currentPage;
  set currentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  GlobalProvider();
}