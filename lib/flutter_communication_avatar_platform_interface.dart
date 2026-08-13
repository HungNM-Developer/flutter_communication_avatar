import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_communication_avatar_method_channel.dart';

abstract class FlutterCommunicationAvatarPlatform extends PlatformInterface {
  /// Constructs a FlutterCommunicationAvatarPlatform.
  FlutterCommunicationAvatarPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterCommunicationAvatarPlatform _instance = MethodChannelFlutterCommunicationAvatar();

  /// The default instance of [FlutterCommunicationAvatarPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterCommunicationAvatar].
  static FlutterCommunicationAvatarPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterCommunicationAvatarPlatform] when
  /// they register themselves.
  static set instance(FlutterCommunicationAvatarPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
