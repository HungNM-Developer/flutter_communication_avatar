import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_communication_avatar/flutter_communication_avatar.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterCommunicationAvatarPlatform
    with MockPlatformInterfaceMixin
    implements FlutterCommunicationAvatarPlatform {
  @override
  Future<bool> showNotification(CommunicationNotification notification) async => true;

  @override
  Future<bool> createNotificationChannel(NotificationChannelConfig config) async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAllNotifications() async {}
}

void main() {
  final FlutterCommunicationAvatarPlatform initialPlatform =
      FlutterCommunicationAvatarPlatform.instance;

  test('$MethodChannelFlutterCommunicationAvatar is default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterCommunicationAvatar>());
  });

  test('showNotification calls platform interface', () async {
    final mockPlatform = MockFlutterCommunicationAvatarPlatform();
    FlutterCommunicationAvatarPlatform.instance = mockPlatform;

    final person = const CommunicationPerson(
      id: 'user_1',
      name: 'Alice Smith',
      avatarUrl: 'https://example.com/avatar.png',
    );

    final notification = CommunicationNotification(
      id: 101,
      body: 'Hello World',
      sender: person,
      conversationId: 'chat_123',
    );

    final result = await FlutterCommunicationAvatar.instance.showNotification(notification);
    expect(result, isTrue);
  });

  test('requestPermissions calls platform interface', () async {
    final mockPlatform = MockFlutterCommunicationAvatarPlatform();
    FlutterCommunicationAvatarPlatform.instance = mockPlatform;

    final result = await FlutterCommunicationAvatar.instance.requestPermissions();
    expect(result, isTrue);
  });
}
