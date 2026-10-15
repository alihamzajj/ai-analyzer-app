/// Summary metadata extracted during parsing.
class ChatMetadata {
  final List<String> participants;
  final Map<String, int> messageCountByParticipant;
  final Map<String, int> mediaCountByParticipant;
  final int totalMessages;
  final int totalMedia;
  final int totalDeleted;
  final int totalSystem;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> warnings;

  const ChatMetadata({
    required this.participants,
    required this.messageCountByParticipant,
    required this.mediaCountByParticipant,
    required this.totalMessages,
    required this.totalMedia,
    required this.totalDeleted,
    required this.totalSystem,
    required this.startDate,
    required this.endDate,
    required this.warnings,
  });

  bool get isGroupChat => participants.length > 2;

  Map<String, dynamic> toJson() => {
        'participants': participants,
        'message_count_by_participant': messageCountByParticipant,
        'media_count_by_participant': mediaCountByParticipant,
        'total_messages': totalMessages,
        'total_media': totalMedia,
        'total_deleted': totalDeleted,
        'total_system': totalSystem,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'warnings': warnings,
        'is_group_chat': isGroupChat,
      };

  factory ChatMetadata.fromJson(Map<String, dynamic> json) {
    return ChatMetadata(
      participants: List<String>.from(json['participants'] ?? []),
      messageCountByParticipant:
          Map<String, int>.from(json['message_count_by_participant'] ?? {}),
      mediaCountByParticipant:
          Map<String, int>.from(json['media_count_by_participant'] ?? {}),
      totalMessages: json['total_messages'] as int? ?? 0,
      totalMedia: json['total_media'] as int? ?? 0,
      totalDeleted: json['total_deleted'] as int? ?? 0,
      totalSystem: json['total_system'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}
