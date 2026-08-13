import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_communication_avatar_method_channel.dart';
import 'models/communication_notification.dart';
import 'models/notification_channel_config.dart';

abstract class FlutterCommunicationAvatarPlatform extends PlatformInterface {
  /// Constructs a FlutterCommunicationAvatarPlatform.
  FlutterCommunicationAvatarPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterCommunicationAvatarPlatform _instance =
      MethodChannelFlutterCommunicationAvatar();

  /// The default instance of [FlutterCommunicationAvatarPlatform] to use.
  static FlutterCommunicationAvatarPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterCommunicationAvatarPlatform] when
  /// they register themselves.
  static set instance(FlutterCommunicationAvatarPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Displays a native communication notification with sender avatar.
  Future<bool> showNotification(CommunicationNotification notification) {
    throw UnimplementedError('showNotification() has not been implemented.');
  }

  /// Creates a notification channel on Android.
  Future<bool> createNotificationChannel(NotificationChannelConfig config) {
    throw UnimplementedError('createNotificationChannel() has not been implemented.');
  }

  /// Requests notification permissions on iOS and Android.
  Future<bool> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  /// Checks whether notification permission is granted.
  Future<bool> hasPermissions() {
    throw UnimplementedError('hasPermissions() has not been implemented.');
  }

  /// Cancels a specific notification by ID.
  Future<void> cancelNotification(int id) {
    throw UnimplementedError('cancelNotification() has not been implemented.');
  }

  /// Cancels all active notifications.
  Future<void> cancelAllNotifications() {
    throw UnimplementedError('cancelAllNotifications() has not been implemented.');
  }
}
