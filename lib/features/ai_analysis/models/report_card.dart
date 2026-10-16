/// Distinct card types in the AI analysis results deck.
enum ReportCardType {
  interestMeter,
  situationshipStatus,
  simpScore,
  compatibilityScore,
  redFlags,
  greenFlags,
  doubleTextChampion,
  dryTexterDetector,
  effortGap,
  textingPersonality,
  groupRoles,
  chatWrapped,
  roastMode,
  whosTheProblem,
}

/// An individual insight card in the analysis deck.
class ReportCard {
  final ReportCardType type;
  final String title;
  final String subtitle;
  final String summary;
  final int? score; // 0 - 100 where applicable
  final String confidence; // 'low', 'medium', 'high'
  final List<String> messageIds; // Stable IDs pointing to real messages for receipts
  final Map<String, dynamic> extraData; // Specific payload for custom visualizations

  const ReportCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.summary,
    this.score,
    this.confidence = 'high',
    this.messageIds = const [],
    this.extraData = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'summary': summary,
        'score': score,
        'confidence': confidence,
        'message_ids': messageIds,
        'extra_data': extraData,
      };

  static ReportCardType parseType(dynamic raw) {
    if (raw == null) return ReportCardType.chatWrapped;
    final str = raw.toString().replaceAll(RegExp(r'[-_\s]'), '').toLowerCase();
    for (final val in ReportCardType.values) {
      if (val.name.toLowerCase() == str) {
        return val;
      }
    }
    return ReportCardType.chatWrapped;
  }

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    return ReportCard(
      type: parseType(json['type']),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      score: json['score'] as int?,
      confidence: json['confidence'] as String? ?? 'medium',
      messageIds: List<String>.from(json['message_ids'] ?? []),
      extraData: json['extra_data'] != null
          ? Map<String, dynamic>.from(json['extra_data'] as Map)
          : const {},
    );
  }
}
