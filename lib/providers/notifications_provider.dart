import 'package:flutter/material.dart';
import 'package:teamup/widgets/notification_widget.dart';

class NotificationsProvider extends ChangeNotifier {

  bool isNotificationVisible = false;
  ImageProvider? icon;
  String title = '';
  String body = '';

  void showNotification(ImageProvider icon, String title, String body, BuildContext context) {
    this.icon = icon;
    this.title = title;
    this.body = body;

    isNotificationVisible = true;
    
    Overlay.of(context).insert(
        OverlayEntry(builder: (context) {
          final size = MediaQuery.of(context).size;
          return Positioned(
            width: 56,
            height: 56,
            top: size.height - 72,
            left: size.width - 72,
            child: NotificationWidget(icon: icon, title: title, body: body)
          );
        }),
      );

    notifyListeners();
  }

  void hideNotification() {
    title = '';
    body = '';
    icon = null;
    isNotificationVisible = false;
    isNotificationVisible = false;
    notifyListeners();
  }
  
  NotificationsProvider();
}