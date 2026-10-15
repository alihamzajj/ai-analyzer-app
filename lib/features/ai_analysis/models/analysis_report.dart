import 'report_card.dart';
import '../../statistics/models/chat_statistics.dart';

/// Complete saved analysis report containing AI cards and verified message receipts.
class AnalysisReport {
  final String id;
  final String conversationHash;
  final DateTime createdAt;
  final String relationshipType;
  final String language;
  final String userParticipant;
  final List<String> participants;
  final List<ReportCard> cards;
  final ReportCard? teaserInsight;
  final ChatStatistics statistics;

  const AnalysisReport({
    required this.id,
    required this.conversationHash,
    required this.createdAt,
    required this.relationshipType,
    required this.language,
    required this.userParticipant,
    required this.participants,
    required this.cards,
    this.teaserInsight,
    required this.statistics,
  });

  /// Participants other than the user who owns this report.
  List<String> get otherParticipants =>
      participants.where((p) => p != userParticipant).toList();

  /// Primary counterpart in a 1:1 chat (first other participant).
  String get otherPerson =>
      otherParticipants.isNotEmpty ? otherParticipants.first : 'Them';

  bool get isGroup => participants.length > 2;

  /// The Interest Meter card, if the AI deck produced one.
  ReportCard? get interestCard {
    for (final c in cards) {
      if (c.type == ReportCardType.interestMeter) return c;
    }
    if (teaserInsight?.type == ReportCardType.interestMeter) return teaserInsight;
    return null;
  }

  /// Headline 0–100 score: Interest Meter first, else the first scored card.
  int? get headlineScore {
    final interest = interestCard?.score;
    if (interest != null) return interest;
    for (final c in cards) {
      if (c.score != null) return c.score;
    }
    return teaserInsight?.score;
  }

  /// Best available AI interpretation blurb.
  ReportCard? get interpretationCard =>
      interestCard ?? teaserInsight ?? (cards.isNotEmpty ? cards.first : null);

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_hash': conversationHash,
        'created_at': createdAt.toIso8601String(),
        'relationship_type': relationshipType,
        'language': language,
        'user_participant': userParticipant,
        'participants': participants,
        'cards': cards.map((c) => c.toJson()).toList(),
        'teaser_insight': teaserInsight?.toJson(),
        'statistics': statistics.toJson(),
      };

  factory AnalysisReport.fromJson(Map<String, dynamic> json) {
    return AnalysisReport(
      id: json['id'] as String,
      conversationHash: json['conversation_hash'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      relationshipType: json['relationship_type'] as String,
      language: json['language'] as String? ?? 'en',
      userParticipant: json['user_participant'] as String,
      participants: List<String>.from(json['participants'] ?? []),
      cards: (json['cards'] as List? ?? [])
          .map((c) => ReportCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      teaserInsight: json['teaser_insight'] != null
          ? ReportCard.fromJson(json['teaser_insight'] as Map<String, dynamic>)
          : null,
      statistics:
          ChatStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
    );
  }
}
