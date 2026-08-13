## 1.0.0

* Initial release of `flutter_communication_avatar`.
* Native communication push notifications with user avatars on iOS (`INSendMessageIntent` + `INPerson` + `INInteraction`) and Android (`MessagingStyle` + `Person` + avatar bitmap on left).
* Asynchronous avatar image downloading over HTTP/HTTPS with automatic caching and fallback generation.
* Support for `UNNotificationServiceExtension` on iOS to format incoming remote push notifications.
* CLI setup tool `bin/setup_ios.dart` for automated iOS `Info.plist` and extension configuration.
* Comprehensive Dart API and interactive example application.
