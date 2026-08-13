import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_communication_avatar/flutter_communication_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFlutterCommunicationAvatar();
  const channel = MethodChannel('flutter_communication_avatar');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'showNotification':
          return true;
        case 'requestPermissions':
          return true;
        case 'hasPermissions':
          return true;
        case 'createNotificationChannel':
          return true;
        case 'clearAvatarCache':
          return true;
        case 'cancelNotification':
        case 'cancelAllNotifications':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('showNotification method channel call', () async {
    const person = CommunicationPerson(
      id: 'user_1',
      name: 'Alice',
    );
    const notification = CommunicationNotification(
      id: 1,
      body: 'Hello',
      sender: person,
      conversationId: 'conv_1',
      replyPlaceholder: 'Type a message...',
      replyButtonTitle: 'Reply',
    );
    expect(await platform.showNotification(notification), isTrue);
  });

  test('requestPermissions method channel call', () async {
    expect(await platform.requestPermissions(), isTrue);
  });

  test('hasPermissions method channel call', () async {
    expect(await platform.hasPermissions(), isTrue);
  });

  test('cancelNotification method channel call', () async {
    await platform.cancelNotification(1);
  });

  test('clearAvatarCache method channel call', () async {
    expect(await platform.clearAvatarCache(), isTrue);
  });

  test('onReplyReceived handles incoming channel call', () async {
    String? replyText;
    int? notifId;
    String? convId;

    platform.onReplyReceived((text, notificationId, conversationId) {
      replyText = text;
      notifId = notificationId;
      convId = conversationId;
    });

    // Simulate incoming method call from native side
    final ByteData? handleResult = await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'flutter_communication_avatar',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onReplyReceived', {
          'text': 'Got it, see you then!',
          'notificationId': 202,
          'conversationId': 'chat_456',
        }),
      ),
      (ByteData? data) {},
    );

    expect(handleResult, isNotNull);
    expect(replyText, equals('Got it, see you then!'));
    expect(notifId, equals(202));
    expect(convId, equals('chat_456'));
  });
}
