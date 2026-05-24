import 'package:flutter/material.dart';
import 'package:teamup/widgets/top_notification.dart';

/// A callback function type for notification actions
typedef NotificationActionCallback = void Function();

/// A class to store notification data
class NotificationData {
  final String title;
  final String message;
  final ImageProvider? icon;
  final NotificationActionCallback? onAction;
  final NotificationActionCallback? onDismissed;
  final Duration? displayDuration;

  NotificationData({
    required this.title,
    required this.message,
    this.icon,
    this.onAction,
    this.onDismissed,
    this.displayDuration,
  });
}

class NotificationsProvider extends ChangeNotifier {

  bool isNotificationVisible = false;
  NotificationData? currentNotification;
  OverlayEntry? _overlayEntry;

  /// Show a notification at the top of the screen that can be swiped away
  void showNotification(
    ImageProvider icon,
    String title,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onAction,
    VoidCallback? onDismissed,
    Duration? displayDuration,
  }) {
    // Create notification data
    currentNotification = NotificationData(
      title: title,
      message: message,
      icon: icon,
      onAction: onAction,
      onDismissed: onDismissed,
      displayDuration: displayDuration,
    );

    isNotificationVisible = true;
    notifyListeners();
  }

  /// Show a notification with custom widget as trailing content
  void showNotificationWithAction(
    ImageProvider icon,
    String title,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Widget? trailingWidget,
    VoidCallback? onDismissed,
    Duration? displayDuration,
  }) {
    // Create notification data
    currentNotification = NotificationData(
      title: title,
      message: message,
      icon: icon,
      onDismissed: onDismissed,
      displayDuration: displayDuration,
    );

    isNotificationVisible = true;
    notifyListeners();
    
    // Show the notification in overlay
    showOverlayNotification(
      title,
      message,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
      trailingWidget: trailingWidget,
      onDismissed: onDismissed,
      displayDuration: displayDuration,
    );
  }

  /// Internal method to show the notification in overlay
  void showOverlayNotification(
    String title,
    String message, {
    ImageProvider? icon,
    Color? backgroundColor,
    Color? textColor,
    Widget? trailingWidget,
    VoidCallback? onDismissed,
    Duration? displayDuration,
  }) {
    // Remove existing overlay if any
    removeOverlay();
    
    // Create new overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Navigator(
          onGenerateRoute: (_) {
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) {
                return TopNotification(
                  title: title,
                  message: message,
                  icon: icon,
                  backgroundColor: backgroundColor,
                  textColor: textColor,
                  trailingWidget: trailingWidget,
                  onDismissed: () {
                    // Call the provided onDismissed callback
                    onDismissed?.call();
                    // Remove from provider state
                    hideNotification();
                  },
                  displayDuration: displayDuration,
                );
              },
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            );
          },
        );
      },
    );
    
    // Insert overlay
    Overlay.of(_globalContext!)?.insert(_overlayEntry!);
  }

  /// Context to use for overlay operations
  BuildContext? _globalContext;
  
  /// Set the global context for overlay operations
  void setContext(BuildContext context) {
    _globalContext = context;
  }

  /// Hide the current notification
  void hideNotification() {
    currentNotification = null;
    isNotificationVisible = false;
    removeOverlay();
    notifyListeners();
  }

  /// Show a simple notification
  void showSimpleNotification(
    String title,
    String message, {
    ImageProvider? icon,
    Duration? duration,
  }) {
    showNotification(
      icon ?? const AssetImage('assets/images/app_icon.png'),
      title,
      message,
      displayDuration: duration ?? const Duration(seconds: 3),
    );
  }
  
  /// Remove the overlay entry
  void removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
  
  NotificationsProvider();
}