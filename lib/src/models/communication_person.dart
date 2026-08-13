/// Represents a person (sender or recipient) involved in a communication notification.
class CommunicationPerson {
  /// Unique identifier for the person (e.g. user ID or phone number).
  final String id;

  /// Display name of the person (e.g. "Alice Smith").
  final String name;

  /// Optional HTTP/HTTPS URL for the person's avatar image.
  final String? avatarUrl;

  /// Optional Flutter asset path (e.g. "assets/avatar.png") as a fallback image.
  final String? fallbackAsset;

  /// Whether this person is a bot or automated assistant.
  final bool isBot;

  /// Whether this person is marked as important (high priority contact).
  final bool isImportant;

  const CommunicationPerson({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.fallbackAsset,
    this.isBot = false,
    this.isImportant = false,
  });

  /// Converts the [CommunicationPerson] instance to a JSON-encodable map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'fallbackAsset': fallbackAsset,
      'isBot': isBot,
      'isImportant': isImportant,
    };
  }

  /// Creates a [CommunicationPerson] instance from a map.
  factory CommunicationPerson.fromMap(Map<String, dynamic> map) {
    return CommunicationPerson(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      fallbackAsset: map['fallbackAsset'] as String?,
      isBot: map['isBot'] as bool? ?? false,
      isImportant: map['isImportant'] as bool? ?? false,
    );
  }
}
