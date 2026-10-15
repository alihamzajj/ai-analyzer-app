import 'message_type.dart';

/// Canonical immutable model for a parsed message.
class ParsedMessage {
  final String id;
  final int index;
  final DateTime? timestamp;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final Map<String, dynamic> metadata;

  const ParsedMessage({
    required this.id,
    required this.index,
    required this.timestamp,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    this.metadata = const {},
  });

  bool get isUserMessage => type == MessageType.text;
  bool get isMedia => type == MessageType.media;
  bool get isSystem => type == MessageType.system;
  bool get isDeleted => type == MessageType.deleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'index': index,
        'timestamp': timestamp?.toIso8601String(),
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
        'type': type.name,
        'metadata': metadata,
      };

  factory ParsedMessage.fromJson(Map<String, dynamic> json) {
    return ParsedMessage(
      id: json['id'] as String,
      index: json['index'] as int,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  ParsedMessage copyWith({
    String? id,
    int? index,
    DateTime? timestamp,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    Map<String, dynamic>? metadata,
  }) {
    return ParsedMessage(
      id: id ?? this.id,
      index: index ?? this.index,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }
}
