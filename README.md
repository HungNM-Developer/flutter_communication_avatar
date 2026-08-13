# flutter_communication_avatar

[![pub package](https://img.shields.io/pub/v/flutter_communication_avatar.svg)](https://pub.dev/packages/flutter_communication_avatar)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)

A production-ready Flutter plugin for displaying **native communication push and local notifications with user avatars** on iOS and Android.

Unlike standard notifications, `flutter_communication_avatar` leverages native system APIs to render user avatars prominently on the **LEFT** side of notifications (overlaying the app icon on iOS 15+ and formatted as native `MessagingStyle` on Android), providing a modern messaging experience similar to iMessage, WhatsApp, and Telegram.

---

## ✨ Features

- **iOS Communication Notifications**: Full support for `INSendMessageIntent`, `INPerson`, `INInteraction`, and iOS 15+ notification content updates. Avatar renders on the **LEFT** overlaying the app icon.
- **Android MessagingStyle**: Full support for `NotificationCompat.MessagingStyle` + `Person` + `IconCompat.createWithBitmap`. Avatar renders on the **LEFT** side of notifications.
- **Inline Quick Reply**: Respond directly from notification banners via `RemoteInput` + `BroadcastReceiver` on Android and `UNTextInputNotificationAction` + `UNNotificationCategory` on iOS. Listen to replies via `onReplyReceived`.
- **Smart Disk Avatar Cache (0ms)**: Hashes `avatarUrl` into persistent local disk cache directory (`context.cacheDir` on Android, `cachesDirectory` on iOS) for 0ms instant loads on subsequent messages. Clear cache using `clearAvatarCache()`.
- **Async Avatar Downloading**: Downloads avatar images asynchronously over HTTP/HTTPS with timeout and caching.
- **Automatic Fallback Avatar**: If the avatar URL fails, times out, or is omitted, automatically generates a clean circular initial letter badge avatar or uses a custom Flutter asset.
- **UNNotificationServiceExtension Support**: Includes a Swift extension helper (`CommunicationAvatarExtensionHelper`) for formatting remote push notifications (FCM / APNs) on iOS.
- **Automated CLI Setup**: CLI tool (`bin/setup_ios.dart`) to inspect and update iOS project settings automatically.
- **Permission & Channel Management**: Built-in permission request/check API and Android Notification Channel builder.

---

## 📸 Platform Display Matrix

| Platform | Native API | Avatar Location | Quick Reply |
| :--- | :--- | :--- | :--- |
| **iOS 15+** | `INSendMessageIntent` + `INPerson` + `UNNotificationContent` | **LEFT** (overlaying app icon) | `UNTextInputNotificationAction` |
| **Android 8.0+** | `NotificationCompat.MessagingStyle` + `Person` | **LEFT** (native messaging avatar) | `RemoteInput` |

---

## 🚀 Getting Started

Add `flutter_communication_avatar` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_communication_avatar: ^1.1.0
```

Run `flutter pub get` to install.

---

## 📱 Platform Setup

### iOS Setup

#### 1. Automated Setup via CLI (Recommended)

Run the included setup script inside your Flutter project directory:

```bash
# Check current iOS configuration status:
dart run flutter_communication_avatar:setup_ios --check

# Automatically update Info.plist with INSendMessageIntent:
dart run flutter_communication_avatar:setup_ios --apply
```

#### 2. Manual Info.plist Setup

Add `INSendMessageIntent` to `NSUserActivityTypes` in your `ios/Runner/Info.plist`:

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>INSendMessageIntent</string>
</array>
```

#### 3. Remote Push Notifications (Notification Service Extension)

To display avatars for remote push notifications when your app is in the background or killed on iOS:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Go to **File -> New -> Target**, select **Notification Service Extension**, and name it `NotificationServiceExtension`.
3. In `NotificationService.swift`, use the plugin's Swift helper:

```swift
import UserNotifications
import Intents
import flutter_communication_avatar

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler

        // Automatically format remote notification payload into INSendMessageIntent with avatar
        CommunicationAvatarExtensionHelper.processNotificationRequest(request) { finalContent in
            contentHandler(finalContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler {
            contentHandler(UNMutableNotificationContent())
        }
    }
}
```

---

### Android Setup

On Android 13+ (API level 33+), ensure you request notification permissions at runtime using the plugin API.

No complex AndroidManifest changes are required. Notification channels and quick reply broadcast receivers are registered automatically.

---

## 💻 Code Examples

### 1. Basic Communication Notification

```dart
import 'package:flutter_communication_avatar/flutter_communication_avatar.dart';

Future<void> sendChatNotification() async {
  // 1. Request notification permissions
  final granted = await FlutterCommunicationAvatar.instance.requestPermissions();
  if (!granted) return;

  // 2. Define sender person with avatar URL
  final sender = CommunicationPerson(
    id: 'user_alice_123',
    name: 'Alice Smith',
    avatarUrl: 'https://example.com/avatars/alice.png',
  );

  // 3. Construct notification
  final notification = CommunicationNotification(
    id: 1001,
    body: 'Hey! Are we still meeting for coffee at 3 PM?',
    sender: sender,
    conversationId: 'chat_alice_123',
  );

  // 4. Post notification
  await FlutterCommunicationAvatar.instance.showNotification(notification);
}
```

---

### 2. Inline Quick Reply Notification

Enable direct text response inputs on notification banners across iOS and Android:

```dart
// 1. Listen for inline quick replies anywhere in your Flutter app
FlutterCommunicationAvatar.instance.onReplyReceived((String text, int notificationId, String conversationId) {
  print('User replied "$text" to notification $notificationId in conversation $conversationId');
  // Send reply back to server / update local UI...
});

// 2. Send notification with inline quick reply input enabled
final notification = CommunicationNotification(
  id: 1004,
  body: 'Are you ready for the meeting?',
  sender: const CommunicationPerson(
    id: 'user_bob_456',
    name: 'Bob Johnson',
    avatarUrl: 'https://example.com/avatars/bob.png',
  ),
  conversationId: 'chat_bob_456',
  replyPlaceholder: 'Type a reply...',
  replyButtonTitle: 'Send Reply',
);

await FlutterCommunicationAvatar.instance.showNotification(notification);
```

---

### 3. Smart Disk Avatar Cache (0ms Instant Load)

Avatars are automatically hashed and persisted on local disk (`context.cacheDir` on Android, `cachesDirectory` on iOS). Subsequent messages from the same avatar URL load instantly in 0ms without network overhead.

To clear disk cached avatars:

```dart
final cleared = await FlutterCommunicationAvatar.instance.clearAvatarCache();
print('Avatar cache cleared: $cleared');
```

---

### 4. Group Conversation Notification

```dart
final sender = CommunicationPerson(
  id: 'user_bob_456',
  name: 'Bob Johnson',
  avatarUrl: 'https://example.com/avatars/bob.png',
);

final notification = CommunicationNotification(
  id: 1002,
  title: 'Project Alpha Team',
  body: 'Pull request #42 has been merged into main!',
  sender: sender,
  conversationId: 'group_project_alpha',
  conversationTitle: 'Project Alpha Team',
  isGroupConversation: true,
);

await FlutterCommunicationAvatar.instance.showNotification(notification);
```

---

### 5. Fallback Avatar (Initial Letter Badge)

If no `avatarUrl` is provided or if network download fails, a letter avatar is automatically generated:

```dart
final sender = CommunicationPerson(
  id: 'user_charlie_789',
  name: 'Charlie Brown',
  // avatarUrl is omitted or null
);

final notification = CommunicationNotification(
  id: 1003,
  body: 'Automatic letter badge fallback avatar test!',
  sender: sender,
  conversationId: 'chat_charlie_789',
);

await FlutterCommunicationAvatar.instance.showNotification(notification);
```

---

### 6. Managing Notification Channels (Android)

```dart
await FlutterCommunicationAvatar.instance.createNotificationChannel(
  const NotificationChannelConfig(
    id: 'custom_chat_channel',
    name: 'Direct Messages',
    description: 'High priority notifications for direct chat messages.',
    importance: 4, // High importance for heads-up banner
  ),
);
```

---

### 7. Canceling Notifications

```dart
// Cancel specific notification by ID
await FlutterCommunicationAvatar.instance.cancelNotification(1001);

// Cancel all active notifications
await FlutterCommunicationAvatar.instance.cancelAllNotifications();
```

---

## 🛠️ CLI Setup Tool (`setup_ios`)

The plugin includes a CLI utility executable for Flutter projects:

```bash
# Display CLI usage
dart run flutter_communication_avatar:setup_ios --help

# Check iOS entitlement status
dart run flutter_communication_avatar:setup_ios --check

# Apply Info.plist updates automatically
dart run flutter_communication_avatar:setup_ios --apply

# Generate NotificationService.swift template
dart run flutter_communication_avatar:setup_ios --extension
```

---

## 📖 API Reference

### `CommunicationPerson`

| Property | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique sender user identifier. |
| `name` | `String` | Display name of the person. |
| `avatarUrl` | `String?` | Optional HTTP/HTTPS image URL for the avatar. |
| `fallbackAsset` | `String?` | Optional local Flutter asset path fallback. |
| `isBot` | `bool` | Whether person is an automated bot. |
| `isImportant` | `bool` | High-priority person flag. |

---

### `CommunicationNotification`

| Property | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | Unique notification integer ID. |
| `body` | `String` | Message content text. |
| `sender` | `CommunicationPerson` | Sender details. |
| `conversationId` | `String` | Room / thread identifier. |
| `conversationTitle`| `String?` | Optional group chat title. |
| `isGroupConversation` | `bool` | Flag for group conversations. |
| `channelId` | `String` | Android notification channel ID. |
| `sound` | `String?` | Notification sound ("default" or custom). |
| `replyPlaceholder` | `String?` | Placeholder text for inline quick reply field. |
| `replyButtonTitle` | `String?` | Button text for quick reply action. |

---

### `FlutterCommunicationAvatar` (Plugin Methods)

| Method | Return Type | Description |
| :--- | :--- | :--- |
| `showNotification(notification)` | `Future<bool>` | Displays communication notification with avatar. |
| `onReplyReceived(callback)` | `void` | Registers listener for inline quick replies. |
| `clearAvatarCache()` | `Future<bool>` | Clears persistent disk avatar cache. |
| `requestPermissions()` | `Future<bool>` | Requests notification permissions. |
| `hasPermissions()` | `Future<bool>` | Checks if notification permissions granted. |
| `cancelNotification(id)` | `Future<void>` | Cancels specific notification. |
| `cancelAllNotifications()` | `Future<void>` | Cancels all active notifications. |

---

## 👨‍💻 Author & License

Developed and maintained by **Hùng Nguyễn**.

Distributed under the **MIT License**. See `LICENSE` for details.
