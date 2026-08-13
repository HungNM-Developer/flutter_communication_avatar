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
}
