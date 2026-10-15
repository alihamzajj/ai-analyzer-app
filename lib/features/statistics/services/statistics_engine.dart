import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../chat_parser/models/parsed_message.dart';
import '../models/chat_statistics.dart';
import '../../../core/utils/stopwords.dart';

/// High-performance calculation engine for chat metrics.
/// Designed for O(N) single-pass efficiency to process 100,000+ messages in seconds.
class StatisticsEngine {
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
    unicode: true,
  );

  static final RegExp _wordTokenRegex = RegExp(r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑäöüÄÖÜßàâçèêëîïôûù']{3,}");

  static final List<String> _laughMarkers = [
    'haha', 'hehe', 'lol', 'lmao', 'rofl', 'jaja', 'mdr', '😂', '🤣', 'xd', 'hah',
  ];

  static const List<String> _trackedKeywords = [
    'sorry',
    'thanks',
    'miss you',
    'love',
    'goodnight',
    'good morning',
  ];

  /// Runs statistics calculation in a background isolate using Flutter `compute`.
  static Future<ChatStatistics> calculateAsync(List<ParsedMessage> messages) async {
    return compute(calculate, messages);
  }

  /// Synchronous calculation method.
  static ChatStatistics calculate(List<ParsedMessage> messages) {
    if (messages.isEmpty) {
      return _emptyStatistics();
    }

    int totalUserMessages = 0;
    int totalWords = 0;

    final Map<String, int> participantMessages = {};
    final Map<String, int> participantChars = {};
    final Map<String, int> participantWords = {};

    final Map<String, int> globalWordCounts = {};
    final Map<String, Map<String, int>> participantWordCounts = {};

    final Map<String, int> globalEmojiCounts = {};
    final Map<String, Map<String, int>> participantEmojiCounts = {};

    final Map<String, List<double>> responseTimes = {};
    final Map<String, int> conversationStarters = {};
    final Map<String, int> conversationEnders = {};
    final Map<String, int> doubleTexts = {};
    final Map<String, int> maxDoubleTextStreak = {};

    final List<int> hourlyDistribution = List.filled(24, 0);
    final List<int> dailyDistribution = List.filled(7, 0);

    final Map<String, int> questionCounts = {};
    final Map<String, int> laughCounts = {};
    final Map<String, Map<String, int>> keywordCounts = {};

    final Set<String> activeDays = {};

    String? previousSender;
    DateTime? previousTimestamp;
    int currentConsecutiveStreak = 1;
    double maxSilenceHours = 0.0;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];

      // Only count user conversation messages for conversational metrics
      if (!msg.isUserMessage) {
        continue;
      }

      totalUserMessages++;
      final sender = msg.senderName;
      final text = msg.content;
      final dt = msg.timestamp;

      // Ensure participant maps exist
      participantMessages[sender] = (participantMessages[sender] ?? 0) + 1;
      participantChars[sender] = (participantChars[sender] ?? 0) + text.length;
      participantWordCounts.putIfAbsent(sender, () => {});
      participantEmojiCounts.putIfAbsent(sender, () => {});
      responseTimes.putIfAbsent(sender, () => []);
      conversationStarters.putIfAbsent(sender, () => 0);
      conversationEnders.putIfAbsent(sender, () => 0);
      doubleTexts.putIfAbsent(sender, () => 0);
      maxDoubleTextStreak.putIfAbsent(sender, () => 1);
      questionCounts.putIfAbsent(sender, () => 0);
      laughCounts.putIfAbsent(sender, () => 0);
      keywordCounts.putIfAbsent(sender, () => {for (final k in _trackedKeywords) k: 0});

      // 1. Timestamp-derived metrics
      if (dt != null) {
        hourlyDistribution[dt.hour]++;
        dailyDistribution[dt.weekday - 1]++; // 1 = Monday -> index 0

        // Streak day format YYYY-MM-DD
        final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        activeDays.add(dayKey);

        if (previousTimestamp != null) {
          final diffHours = dt.difference(previousTimestamp).inSeconds / 3600.0;
          if (diffHours > maxSilenceHours) {
            maxSilenceHours = diffHours;
          }

          // Session boundary: silence > 4 hours
          if (diffHours >= 4.0) {
            conversationStarters[sender] = conversationStarters[sender]! + 1;
            if (previousSender != null && previousSender != sender) {
              conversationEnders[previousSender] =
                  (conversationEnders[previousSender] ?? 0) + 1;
            }
          } else if (previousSender != null && previousSender != sender) {
            // Legitimate response within a session
            final diffMinutes = diffHours * 60.0;
            if (diffMinutes >= 0 && diffMinutes <= 240) {
              responseTimes[sender]!.add(diffMinutes);
            }
          }
        } else {
          // Very first message is a conversation starter
          conversationStarters[sender] = conversationStarters[sender]! + 1;
        }

        previousTimestamp = dt;
      }

      // 2. Double text handling
      if (previousSender == sender) {
        doubleTexts[sender] = doubleTexts[sender]! + 1;
        currentConsecutiveStreak++;
        if (currentConsecutiveStreak > maxDoubleTextStreak[sender]!) {
          maxDoubleTextStreak[sender] = currentConsecutiveStreak;
        }
      } else {
        currentConsecutiveStreak = 1;
      }
      previousSender = sender;

      // 3. Questions & Laughter
      final lowerText = text.toLowerCase();
      if (lowerText.contains('?') || lowerText.contains('¿')) {
        questionCounts[sender] = questionCounts[sender]! + 1;
      }

      for (final marker in _laughMarkers) {
        if (lowerText.contains(marker)) {
          laughCounts[sender] = laughCounts[sender]! + 1;
          break;
        }
      }

      // 4. Keyword counters
      for (final keyword in _trackedKeywords) {
        if (lowerText.contains(keyword)) {
          keywordCounts[sender]![keyword] = keywordCounts[sender]![keyword]! + 1;
        }
      }

      // 5. Tokenize words and count emojis
      int msgWords = 0;
      final wordMatches = _wordTokenRegex.allMatches(lowerText);
      for (final match in wordMatches) {
        final word = match.group(0)!;
        msgWords++;
        if (!Stopwords.isStopword(word)) {
          globalWordCounts[word] = (globalWordCounts[word] ?? 0) + 1;
          participantWordCounts[sender]![word] =
              (participantWordCounts[sender]![word] ?? 0) + 1;
        }
      }

      participantWords[sender] = (participantWords[sender] ?? 0) + msgWords;
      totalWords += msgWords;

      // Emojis
      final emojiMatches = _emojiRegex.allMatches(text);
      for (final match in emojiMatches) {
        final emoji = match.group(0)!;
        globalEmojiCounts[emoji] = (globalEmojiCounts[emoji] ?? 0) + 1;
        participantEmojiCounts[sender]![emoji] =
            (participantEmojiCounts[sender]![emoji] ?? 0) + 1;
      }
    }

    // Mark the final message sender as conversation ender
    if (previousSender != null) {
      conversationEnders[previousSender] =
          (conversationEnders[previousSender] ?? 0) + 1;
    }

    // 6. Compute averages and distributions
    final Map<String, double> participantAvgLengthChars = {};
    final Map<String, double> participantAvgLengthWords = {};
    final Map<String, double> avgResponseTimeMinutes = {};
    final Map<String, double> medianResponseTimeMinutes = {};

    for (final participant in participantMessages.keys) {
      final count = participantMessages[participant]!;
      participantAvgLengthChars[participant] =
          count > 0 ? (participantChars[participant] ?? 0) / count : 0.0;
      participantAvgLengthWords[participant] =
          count > 0 ? (participantWords[participant] ?? 0) / count : 0.0;

      final times = responseTimes[participant] ?? [];
      if (times.isNotEmpty) {
        times.sort();
        final sum = times.reduce((a, b) => a + b);
        avgResponseTimeMinutes[participant] = sum / times.length;
        medianResponseTimeMinutes[participant] = times[times.length ~/ 2];
      } else {
        avgResponseTimeMinutes[participant] = 0.0;
        medianResponseTimeMinutes[participant] = 0.0;
      }
    }

    // 7. Calculate longest consecutive daily streak
    final longestStreakDays = _computeLongestDailyStreak(activeDays);

    // 8. Sort Top Words and Top Emojis
    final topWords = _getTopSorted(globalWordCounts, 20)
        .map((e) => WordCount(e.key, e.value))
        .toList();

    final Map<String, List<WordCount>> participantTopWords = {};
    for (final p in participantWordCounts.keys) {
      participantTopWords[p] = _getTopSorted(participantWordCounts[p]!, 10)
          .map((e) => WordCount(e.key, e.value))
          .toList();
    }

    final topEmojis = _getTopSorted(globalEmojiCounts, 15)
        .map((e) => EmojiCount(e.key, e.value))
        .toList();

    final Map<String, List<EmojiCount>> participantTopEmojis = {};
    for (final p in participantEmojiCounts.keys) {
      participantTopEmojis[p] = _getTopSorted(participantEmojiCounts[p]!, 8)
          .map((e) => EmojiCount(e.key, e.value))
          .toList();
    }

    return ChatStatistics(
      totalMessages: totalUserMessages,
      totalWords: totalWords,
      participantMessages: participantMessages,
      participantWords: participantWords,
      participantAvgLengthChars: participantAvgLengthChars,
      participantAvgLengthWords: participantAvgLengthWords,
      topWords: topWords,
      participantTopWords: participantTopWords,
      topEmojis: topEmojis,
      participantTopEmojis: participantTopEmojis,
      avgResponseTimeMinutes: avgResponseTimeMinutes,
      medianResponseTimeMinutes: medianResponseTimeMinutes,
      conversationStarters: conversationStarters,
      conversationEnders: conversationEnders,
      doubleTexts: doubleTexts,
      maxDoubleTextStreak: maxDoubleTextStreak,
      longestDailyStreakDays: longestStreakDays,
      longestSilenceHours: maxSilenceHours,
      hourlyDistribution: hourlyDistribution,
      dailyDistribution: dailyDistribution,
      questionCounts: questionCounts,
      laughCounts: laughCounts,
      keywordCounts: keywordCounts,
    );
  }

  static List<MapEntry<String, int>> _getTopSorted(Map<String, int> counts, int limit) {
    final list = counts.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  static int _computeLongestDailyStreak(Set<String> activeDayStrings) {
    if (activeDayStrings.isEmpty) return 0;

    final List<DateTime> days = activeDayStrings
        .map((d) => DateTime.parse(d))
        .toList()
      ..sort();

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < days.length; i++) {
      final prev = days[i - 1];
      final curr = days[i];
      final diff = curr.difference(prev).inDays;

      if (diff == 1) {
        currentStreak++;
        maxStreak = max(maxStreak, currentStreak);
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  static ChatStatistics _emptyStatistics() {
    return ChatStatistics(
      totalMessages: 0,
      totalWords: 0,
      participantMessages: {},
      participantWords: {},
      participantAvgLengthChars: {},
      participantAvgLengthWords: {},
      topWords: [],
      participantTopWords: {},
      topEmojis: [],
      participantTopEmojis: {},
      avgResponseTimeMinutes: {},
      medianResponseTimeMinutes: {},
      conversationStarters: {},
      conversationEnders: {},
      doubleTexts: {},
      maxDoubleTextStreak: {},
      longestDailyStreakDays: 0,
      longestSilenceHours: 0.0,
      hourlyDistribution: List.filled(24, 0),
      dailyDistribution: List.filled(7, 0),
      questionCounts: {},
      laughCounts: {},
      keywordCounts: {},
    );
  }
}
