/// Typed model containing all computed chat metrics and distributions.
class ChatStatistics {
  final int totalMessages;
  final int totalWords;
  final Map<String, int> participantMessages;
  final Map<String, int> participantWords;
  final Map<String, double> participantAvgLengthChars;
  final Map<String, double> participantAvgLengthWords;
  final List<WordCount> topWords;
  final Map<String, List<WordCount>> participantTopWords;
  final List<EmojiCount> topEmojis;
  final Map<String, List<EmojiCount>> participantTopEmojis;
  final Map<String, double> avgResponseTimeMinutes;
  final Map<String, double> medianResponseTimeMinutes;
  final Map<String, int> conversationStarters;
  final Map<String, int> conversationEnders;
  final Map<String, int> doubleTexts;
  final Map<String, int> maxDoubleTextStreak;
  final int longestDailyStreakDays;
  final double longestSilenceHours;
  final List<int> hourlyDistribution; // 24 entries
  final List<int> dailyDistribution; // 7 entries: Monday (0) -> Sunday (6)
  final Map<String, int> questionCounts;
  final Map<String, int> laughCounts;
  final Map<String, Map<String, int>> keywordCounts;

  const ChatStatistics({
    required this.totalMessages,
    required this.totalWords,
    required this.participantMessages,
    required this.participantWords,
    required this.participantAvgLengthChars,
    required this.participantAvgLengthWords,
    required this.topWords,
    required this.participantTopWords,
    required this.topEmojis,
    required this.participantTopEmojis,
    required this.avgResponseTimeMinutes,
    required this.medianResponseTimeMinutes,
    required this.conversationStarters,
    required this.conversationEnders,
    required this.doubleTexts,
    required this.maxDoubleTextStreak,
    required this.longestDailyStreakDays,
    required this.longestSilenceHours,
    required this.hourlyDistribution,
    required this.dailyDistribution,
    required this.questionCounts,
    required this.laughCounts,
    required this.keywordCounts,
  });

  Map<String, dynamic> toJson() => {
        'total_messages': totalMessages,
        'total_words': totalWords,
        'participant_messages': participantMessages,
        'participant_words': participantWords,
        'participant_avg_length_chars': participantAvgLengthChars,
        'participant_avg_length_words': participantAvgLengthWords,
        'top_words': topWords.map((w) => w.toJson()).toList(),
        'participant_top_words': participantTopWords.map(
          (k, v) => MapEntry(k, v.map((w) => w.toJson()).toList()),
        ),
        'top_emojis': topEmojis.map((e) => e.toJson()).toList(),
        'participant_top_emojis': participantTopEmojis.map(
          (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
        ),
        'avg_response_time_minutes': avgResponseTimeMinutes,
        'median_response_time_minutes': medianResponseTimeMinutes,
        'conversation_starters': conversationStarters,
        'conversation_enders': conversationEnders,
        'double_texts': doubleTexts,
        'max_double_text_streak': maxDoubleTextStreak,
        'longest_daily_streak_days': longestDailyStreakDays,
        'longest_silence_hours': longestSilenceHours,
        'hourly_distribution': hourlyDistribution,
        'daily_distribution': dailyDistribution,
        'question_counts': questionCounts,
        'laugh_counts': laughCounts,
        'keyword_counts': keywordCounts,
      };

  factory ChatStatistics.fromJson(Map<String, dynamic> json) {
    return ChatStatistics(
      totalMessages: json['total_messages'] as int? ?? 0,
      totalWords: json['total_words'] as int? ?? 0,
      participantMessages:
          Map<String, int>.from(json['participant_messages'] ?? {}),
      participantWords: Map<String, int>.from(json['participant_words'] ?? {}),
      participantAvgLengthChars:
          Map<String, double>.from(json['participant_avg_length_chars'] ?? {}),
      participantAvgLengthWords:
          Map<String, double>.from(json['participant_avg_length_words'] ?? {}),
      topWords: (json['top_words'] as List? ?? [])
          .map((e) => WordCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      participantTopWords:
          (json['participant_top_words'] as Map? ?? {}).map(
        (k, v) => MapEntry(
          k as String,
          (v as List)
              .map((e) => WordCount.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      topEmojis: (json['top_emojis'] as List? ?? [])
          .map((e) => EmojiCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      participantTopEmojis:
          (json['participant_top_emojis'] as Map? ?? {}).map(
        (k, v) => MapEntry(
          k as String,
          (v as List)
              .map((e) => EmojiCount.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      avgResponseTimeMinutes:
          Map<String, double>.from(json['avg_response_time_minutes'] ?? {}),
      medianResponseTimeMinutes:
          Map<String, double>.from(json['median_response_time_minutes'] ?? {}),
      conversationStarters:
          Map<String, int>.from(json['conversation_starters'] ?? {}),
      conversationEnders:
          Map<String, int>.from(json['conversation_enders'] ?? {}),
      doubleTexts: Map<String, int>.from(json['double_texts'] ?? {}),
      maxDoubleTextStreak:
          Map<String, int>.from(json['max_double_text_streak'] ?? {}),
      longestDailyStreakDays:
          json['longest_daily_streak_days'] as int? ?? 0,
      longestSilenceHours:
          (json['longest_silence_hours'] as num?)?.toDouble() ?? 0.0,
      hourlyDistribution:
          List<int>.from(json['hourly_distribution'] ?? List.filled(24, 0)),
      dailyDistribution:
          List<int>.from(json['daily_distribution'] ?? List.filled(7, 0)),
      questionCounts: Map<String, int>.from(json['question_counts'] ?? {}),
      laughCounts: Map<String, int>.from(json['laugh_counts'] ?? {}),
      keywordCounts: (json['keyword_counts'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, Map<String, int>.from(v as Map)),
      ),
    );
  }
}

class WordCount {
  final String word;
  final int count;

  const WordCount(this.word, this.count);

  Map<String, dynamic> toJson() => {'word': word, 'count': count};

  factory WordCount.fromJson(Map<String, dynamic> json) =>
      WordCount(json['word'] as String, json['count'] as int);
}

class EmojiCount {
  final String emoji;
  final int count;

  const EmojiCount(this.emoji, this.count);

  Map<String, dynamic> toJson() => {'emoji': emoji, 'count': count};

  factory EmojiCount.fromJson(Map<String, dynamic> json) =>
      EmojiCount(json['emoji'] as String, json['count'] as int);
}
