/// Configuration settings for creating an Android Notification Channel.
class NotificationChannelConfig {
  /// Unique notification channel ID.
  final String id;

  /// Human-readable channel name shown in Android App Info settings.
  final String name;

  /// Channel description shown in system settings.
  final String? description;

  /// Importance level (0 = none, 1 = min, 2 = low, 3 = default, 4 = high, 5 = max).
  final int importance;

  /// Whether notifications posted to this channel should vibrate.
  final bool enableVibration;

  /// Whether notifications posted to this channel show notification light.
  final bool enableLights;

  /// Notification sound file name or "default".
  final String? sound;

  const NotificationChannelConfig({
    required this.id,
    required this.name,
    this.description,
    this.importance = 4, // HIGH importance by default for communication
    this.enableVibration = true,
    this.enableLights = true,
    this.sound = 'default',
  });

  /// Converts this configuration instance to a JSON-encodable map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'importance': importance,
      'enableVibration': enableVibration,
      'enableLights': enableLights,
      'sound': sound,
    };
  }
}
