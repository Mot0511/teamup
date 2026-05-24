import 'package:flutter/material.dart';
import 'package:teamup/providers/notifications_provider.dart';
import 'package:provider/provider.dart';

/// A helper class to simplify showing notifications in the app
class NotificationHelper {
  /// Show a success notification
  static void showSuccess(
    BuildContext context,
    String title,
    String message, {
    Duration? duration,
  }) {
    final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
    
    notificationsProvider.showSimpleNotification(
      title,
      message,
      icon: const AssetImage('assets/images/success_icon.png'),
      duration: duration,
    );
  }

  /// Show an error notification
  static void showError(
    BuildContext context,
    String title,
    String message, {
    Duration? duration,
  }) {
    final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
    
    notificationsProvider.showSimpleNotification(
      title,
      message,
      icon: const AssetImage('assets/images/error_icon.png'),
      duration: duration,
    );
  }

  /// Show an info notification
  static void showInfo(
    BuildContext context,
    String title,
    String message, {
    Duration? duration,
  }) {
    final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
    
    notificationsProvider.showSimpleNotification(
      title,
      message,
      icon: const AssetImage('assets/images/info_icon.png'),
      duration: duration,
    );
  }

  /// Show a warning notification
  static void showWarning(
    BuildContext context,
    String title,
    String message, {
    Duration? duration,
  }) {
    final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
    
    notificationsProvider.showSimpleNotification(
      title,
      message,
      icon: const AssetImage('assets/images/warning_icon.png'),
      duration: duration,
    );
  }
}