import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_communication_avatar_platform_interface.dart';
import 'models/communication_notification.dart';
import 'models/notification_channel_config.dart';

/// An implementation of [FlutterCommunicationAvatarPlatform] that uses method channels.
class MethodChannelFlutterCommunicationAvatar
    extends FlutterCommunicationAvatarPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_communication_avatar');

  void Function(String text, int notificationId, String conversationId)?
      _onReplyCallback;

  @override
  void onReplyReceived(
      void Function(String text, int notificationId, String conversationId)
          callback) {
    _onReplyCallback = callback;
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onReplyReceived') {
      final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});
      final text = args['text'] as String? ?? '';
      final notificationId = args['notificationId'] as int? ?? 0;
      final conversationId = args['conversationId'] as String? ?? '';
      _onReplyCallback?.call(text, notificationId, conversationId);
    }
  }

  @override
  Future<bool> showNotification(CommunicationNotification notification) async {
    final result = await methodChannel.invokeMethod<bool>(
      'showNotification',
      notification.toMap(),
    );
    return result ?? false;
  }

  @override
  Future<bool> createNotificationChannel(
      NotificationChannelConfig config) async {
    final result = await methodChannel.invokeMethod<bool>(
      'createNotificationChannel',
      config.toMap(),
    );
    return result ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  @override
  Future<bool> hasPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('hasPermissions');
    return result ?? false;
  }

  @override
  Future<void> cancelNotification(int id) async {
    await methodChannel.invokeMethod<void>('cancelNotification', {'id': id});
  }

  @override
  Future<void> cancelAllNotifications() async {
    await methodChannel.invokeMethod<void>('cancelAllNotifications');
  }

  @override
  Future<bool> clearAvatarCache() async {
    final result = await methodChannel.invokeMethod<bool>('clearAvatarCache');
    return result ?? false;
  }
}
