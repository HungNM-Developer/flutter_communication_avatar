import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_communication_avatar/flutter_communication_avatar.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterCommunicationAvatarPlatform
    with MockPlatformInterfaceMixin
    implements FlutterCommunicationAvatarPlatform {
  void Function(String text, int notificationId, String conversationId)?
      replyCallback;

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

  @override
  void onReplyReceived(
      void Function(String text, int notificationId, String conversationId)
          callback) {
    replyCallback = callback;
  }

  @override
  Future<bool> clearAvatarCache() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final FlutterCommunicationAvatarPlatform initialPlatform =
      FlutterCommunicationAvatarPlatform.instance;

  test('$MethodChannelFlutterCommunicationAvatar is default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterCommunicationAvatar>());
  });

  test('showNotification calls platform interface with reply properties', () async {
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
      replyPlaceholder: 'Reply to Alice...',
      replyButtonTitle: 'Send Reply',
    );

    final result = await FlutterCommunicationAvatar.instance.showNotification(notification);
    expect(result, isTrue);
    expect(notification.replyPlaceholder, equals('Reply to Alice...'));
    expect(notification.replyButtonTitle, equals('Send Reply'));
  });

  test('requestPermissions calls platform interface', () async {
    final mockPlatform = MockFlutterCommunicationAvatarPlatform();
    FlutterCommunicationAvatarPlatform.instance = mockPlatform;

    final result = await FlutterCommunicationAvatar.instance.requestPermissions();
    expect(result, isTrue);
  });

  test('onReplyReceived registers listener on platform interface', () {
    final mockPlatform = MockFlutterCommunicationAvatarPlatform();
    FlutterCommunicationAvatarPlatform.instance = mockPlatform;

    String? receivedText;
    int? receivedId;
    String? receivedConvId;

    FlutterCommunicationAvatar.instance.onReplyReceived((text, notificationId, conversationId) {
      receivedText = text;
      receivedId = notificationId;
      receivedConvId = conversationId;
    });

    expect(mockPlatform.replyCallback, isNotNull);
    mockPlatform.replyCallback?.call('Thanks!', 101, 'chat_123');

    expect(receivedText, equals('Thanks!'));
    expect(receivedId, equals(101));
    expect(receivedConvId, equals('chat_123'));
  });

  test('clearAvatarCache calls platform interface', () async {
    final mockPlatform = MockFlutterCommunicationAvatarPlatform();
    FlutterCommunicationAvatarPlatform.instance = mockPlatform;

    final result = await FlutterCommunicationAvatar.instance.clearAvatarCache();
    expect(result, isTrue);
  });
}
