import 'communication_person.dart';

/// Represents a native communication notification payload.
class CommunicationNotification {
  /// Unique integer notification ID.
  final int id;

  /// Main message content / body text.
  final String body;

  /// Optional notification title (defaults to sender's name if null).
  final String? title;

  /// Sender details (person whose avatar will be displayed).
  final CommunicationPerson sender;

  /// Unique conversation identifier (e.g. room ID, thread ID).
  final String conversationId;

  /// Optional group conversation title (e.g. "Design Team").
  final String? conversationTitle;

  /// Whether this notification is part of a group chat.
  final bool isGroupConversation;

  /// Android notification channel ID (defaults to "communication_channel").
  final String channelId;

  /// Android notification channel name (defaults to "Messages").
  final String channelName;

  /// Android notification channel description.
  final String? channelDescription;

  /// Timestamp in milliseconds since epoch (defaults to current time if null).
  final int? timestamp;

  /// Sound name or "default".
  final String? sound;

  /// Optional custom payload data as key-value string map.
  final Map<String, String>? payload;

  const CommunicationNotification({
    required this.id,
    required this.body,
    required this.sender,
    required this.conversationId,
    this.title,
    this.conversationTitle,
    this.isGroupConversation = false,
    this.channelId = 'communication_channel',
    this.channelName = 'Messages',
    this.channelDescription = 'Communication & Messaging Notifications',
    this.timestamp,
    this.sound = 'default',
    this.payload,
  });

  /// Converts the [CommunicationNotification] to a JSON-encodable map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'body': body,
      'title': title,
      'sender': sender.toMap(),
      'conversationId': conversationId,
      'conversationTitle': conversationTitle,
      'isGroupConversation': isGroupConversation,
      'channelId': channelId,
      'channelName': channelName,
      'channelDescription': channelDescription,
      'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
      'sound': sound,
      'payload': payload,
    };
  }

  /// Creates a [CommunicationNotification] from a map.
  factory CommunicationNotification.fromMap(Map<String, dynamic> map) {
    return CommunicationNotification(
      id: map['id'] as int? ?? 0,
      body: map['body'] as String? ?? '',
      title: map['title'] as String?,
      sender: CommunicationPerson.fromMap(
        Map<String, dynamic>.from(map['sender'] as Map? ?? {}),
      ),
      conversationId: map['conversationId'] as String? ?? 'default_conversation',
      conversationTitle: map['conversationTitle'] as String?,
      isGroupConversation: map['isGroupConversation'] as bool? ?? false,
      channelId: map['channelId'] as String? ?? 'communication_channel',
      channelName: map['channelName'] as String? ?? 'Messages',
      channelDescription: map['channelDescription'] as String?,
      timestamp: map['timestamp'] as int?,
      sound: map['sound'] as String? ?? 'default',
      payload: map['payload'] != null
          ? Map<String, String>.from(map['payload'] as Map)
          : null,
    );
  }
}
