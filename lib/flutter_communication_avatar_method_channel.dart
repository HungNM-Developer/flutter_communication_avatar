import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_communication_avatar_platform_interface.dart';

/// An implementation of [FlutterCommunicationAvatarPlatform] that uses method channels.
class MethodChannelFlutterCommunicationAvatar extends FlutterCommunicationAvatarPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_communication_avatar');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
