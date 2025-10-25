import 'package:flutter/material.dart';

class LifecycleEventHandler extends WidgetsBindingObserver {
  LifecycleEventHandler({required this.resumeCallBack, required this.detachedCallBack});
  final Function resumeCallBack;
  final Function detachedCallBack;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        await detachedCallBack();
        break;
      case AppLifecycleState.paused:
        await detachedCallBack();
        break;
      case AppLifecycleState.detached:
        await detachedCallBack();
        break;
      case AppLifecycleState.resumed:
        await resumeCallBack();
        break;
      case AppLifecycleState.hidden:
        await detachedCallBack();
        break;
    }
  }
}