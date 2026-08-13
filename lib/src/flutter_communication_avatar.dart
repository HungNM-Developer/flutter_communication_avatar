import 'flutter_communication_avatar_platform_interface.dart';
import 'models/communication_notification.dart';
import 'models/notification_channel_config.dart';

/// Entry point for displaying native communication push notifications with user avatars.
class FlutterCommunicationAvatar {
  const FlutterCommunicationAvatar._();

  static final FlutterCommunicationAvatar _instance =
      const FlutterCommunicationAvatar._();

  /// Singleton instance.
  static FlutterCommunicationAvatar get instance => _instance;

  /// Displays a native communication notification with user avatar.
  ///
  /// On Android, uses `MessagingStyle` + `Person` + `Icon.createWithBitmap`.
  /// On iOS, uses `INSendMessageIntent` + `INPerson` + `INInteraction` (iOS 15+ avatar overlay).
  Future<bool> showNotification(CommunicationNotification notification) {
    return FlutterCommunicationAvatarPlatform.instance
        .showNotification(notification);
  }

  /// Creates a custom Android Notification Channel for communication messages.
  Future<bool> createNotificationChannel(NotificationChannelConfig config) {
    return FlutterCommunicationAvatarPlatform.instance
        .createNotificationChannel(config);
  }

  /// Requests notification permissions on iOS and Android (POST_NOTIFICATIONS).
  Future<bool> requestPermissions() {
    return FlutterCommunicationAvatarPlatform.instance.requestPermissions();
  }

  /// Checks whether notification permission is granted.
  Future<bool> hasPermissions() {
    return FlutterCommunicationAvatarPlatform.instance.hasPermissions();
  }

  /// Cancels a specific active notification by its integer [id].
  Future<void> cancelNotification(int id) {
    return FlutterCommunicationAvatarPlatform.instance.cancelNotification(id);
  }

  /// Cancels all active notifications.
  Future<void> cancelAllNotifications() {
    return FlutterCommunicationAvatarPlatform.instance.cancelAllNotifications();
  }
}
