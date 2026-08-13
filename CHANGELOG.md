## 1.1.0

* Added **Inline Quick Reply**:
  * Android `RemoteInput` with `BroadcastReceiver` / MethodChannel handling for banner text replies.
  * iOS `UNTextInputNotificationAction` + `UNNotificationCategory` for direct notification replies.
  * Exposed `onReplyReceived((String text, int notificationId, String conversationId) => ...)` listener and `replyPlaceholder`, `replyButtonTitle` on `CommunicationNotification`.
* Added **Smart Disk Avatar Cache (0ms)**:
  * Persistent disk-based avatar image caching by hashing `avatarUrl` into local persistent cache directory (`FileManager.default.cachesDirectory` on iOS, `context.cacheDir` on Android).
  * Instant 0ms load for subsequent messages from the same sender.
  * Exposed `clearAvatarCache()` method in Dart API.

## 1.0.1

* Updated SDK environment constraints and package metadata.
* Updated repository and issue tracker links.

## 1.0.0

* Initial release of `flutter_communication_avatar`.
* Native communication push notifications with user avatars on iOS (`INSendMessageIntent` + `INPerson` + `INInteraction`) and Android (`MessagingStyle` + `Person` + avatar bitmap on left).
* Asynchronous avatar image downloading over HTTP/HTTPS with automatic caching and fallback generation.
* Support for `UNNotificationServiceExtension` on iOS to format incoming remote push notifications.
* CLI setup tool `bin/setup_ios.dart` for automated iOS `Info.plist` and extension configuration.
* Comprehensive Dart API and interactive example application.
