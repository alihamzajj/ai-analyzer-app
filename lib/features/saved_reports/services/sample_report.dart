import '../../ai_analysis/models/analysis_report.dart';
import '../../ai_analysis/models/report_card.dart';
import '../../statistics/models/chat_statistics.dart';

/// A fully-populated demo report so first-time users can explore
/// what a result looks like before importing their own chat.
/// Never saved to storage.
class SampleReport {
  static const String id = 'sample_report';

  static bool isSample(AnalysisReport r) => r.id == id;

  static AnalysisReport build() {
    return AnalysisReport(
      id: id,
      conversationHash: 'sample',
      createdAt: DateTime.now(),
      relationshipType: 'romantic',
      language: 'en',
      userParticipant: 'Alex',
      participants: const ['Alex', 'Sam'],
      cards: const [
        ReportCard(
          type: ReportCardType.interestMeter,
          title: 'Interest Meter',
          subtitle: 'Sam is leaning in',
          summary:
              'Lots of follow-up questions and weekend plans. Weekday mornings run quiet, but late nights are where this chat lives.',
          score: 72,
          confidence: 'medium',
        ),
        ReportCard(
          type: ReportCardType.greenFlags,
          title: 'Green Flags',
          subtitle: '3 things going right',
          summary:
              'Sam remembers small details from past chats, always replies to voice notes, and checks in before big days.',
          confidence: 'high',
        ),
        ReportCard(
          type: ReportCardType.redFlags,
          title: 'Red Flags',
          subtitle: 'Mostly harmless',
          summary:
              'A few "haha ok" replies after long messages. The 6-hour silence after plans got cancelled did not go unnoticed.',
          confidence: 'medium',
        ),
        ReportCard(
          type: ReportCardType.doubleTextChampion,
          title: 'Double-Text Champion',
          subtitle: 'Alex, by a mile',
          summary: 'Alex sent 412 double texts with a personal record of 9 messages in a row. Iconic.',
          score: 81,
          confidence: 'high',
        ),
        ReportCard(
          type: ReportCardType.textingPersonality,
          title: 'Texting Personality',
          subtitle: 'The Night Owl Novelist',
          summary:
              'Peak hour is 23:00 and the average message is 14 words long. This chat writes essays after dark.',
          confidence: 'high',
        ),
        ReportCard(
          type: ReportCardType.roastMode,
          title: 'Roast Mode',
          subtitle: 'Spicy',
          summary:
              'Alex replies in 4 minutes and then pretends to be busy. Sam takes 23 minutes to send "lol". You two are a sitcom.',
          confidence: 'medium',
        ),
        ReportCard(
          type: ReportCardType.compatibilityScore,
          title: 'Compatibility',
          subtitle: 'Strong chemistry',
          summary: 'Similar humour, matched energy on weekends, and you both laugh at your own jokes.',
          score: 78,
          confidence: 'medium',
        ),
      ],
      statistics: ChatStatistics(
        totalMessages: 12480,
        totalWords: 98320,
        participantMessages: const {'Alex': 6720, 'Sam': 5760},
        participantWords: const {'Alex': 51200, 'Sam': 47120},
        participantAvgLengthChars: const {'Alex': 38.2, 'Sam': 41.5},
        participantAvgLengthWords: const {'Alex': 7.6, 'Sam': 8.2},
        topWords: const [
          WordCount('tonight', 412),
          WordCount('haha', 389),
          WordCount('coffee', 211),
          WordCount('weekend', 198),
          WordCount('movie', 154),
          WordCount('miss', 133),
        ],
        participantTopWords: const {},
        topEmojis: const [
          EmojiCount('😂', 822),
          EmojiCount('❤️', 431),
          EmojiCount('🥺', 207),
          EmojiCount('🔥', 96),
        ],
        participantTopEmojis: const {},
        avgResponseTimeMinutes: const {'Alex': 9, 'Sam': 41},
        medianResponseTimeMinutes: const {'Alex': 4, 'Sam': 23},
        conversationStarters: const {'Alex': 55, 'Sam': 45},
        conversationEnders: const {'Alex': 38, 'Sam': 62},
        doubleTexts: const {'Alex': 412, 'Sam': 187},
        maxDoubleTextStreak: const {'Alex': 9, 'Sam': 5},
        longestDailyStreakDays: 41,
        longestSilenceHours: 31,
        hourlyDistribution: const [
          310, 180, 90, 40, 20, 15, 40, 120, 260, 330, 360, 400,
          520, 480, 420, 450, 500, 560, 640, 720, 860, 980, 1160, 1240,
        ],
        dailyDistribution: const [1520, 1480, 1610, 1590, 1930, 2290, 2060],
        questionCounts: const {'Alex': 810, 'Sam': 944},
        laughCounts: const {'Alex': 640, 'Sam': 702},
        keywordCounts: const {},
      ),
    );
  }
}
