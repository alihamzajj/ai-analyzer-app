import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_analyser/features/chat_parser/models/message_type.dart';
import 'package:ai_chat_analyser/features/chat_parser/models/parsed_message.dart';
import 'package:ai_chat_analyser/features/statistics/services/statistics_engine.dart';

void main() {
  group('StatisticsEngine Functional Tests', () {
    test('Calculates accurate metrics for known sample conversation', () {
      final baseDate = DateTime(2023, 5, 1, 10, 0);

      final messages = [
        ParsedMessage(
          id: '1',
          index: 1,
          timestamp: baseDate,
          senderId: 'alice',
          senderName: 'Alice',
          content: 'Good morning! How are you doing? 😂',
          type: MessageType.text,
        ),
        ParsedMessage(
          id: '2',
          index: 2,
          timestamp: baseDate.add(const Duration(minutes: 5)),
          senderId: 'bob',
          senderName: 'Bob',
          content: 'Doing great thanks! What about you?',
          type: MessageType.text,
        ),
        ParsedMessage(
          id: '3',
          index: 3,
          timestamp: baseDate.add(const Duration(minutes: 6)),
          senderId: 'bob',
          senderName: 'Bob',
          content: 'Are we meeting later today?',
          type: MessageType.text,
        ),
        ParsedMessage(
          id: '4',
          index: 4,
          timestamp: baseDate.add(const Duration(hours: 6)), // > 4 hrs silence -> new session
          senderId: 'alice',
          senderName: 'Alice',
          content: 'Sorry for the delay! Love you lots ❤️',
          type: MessageType.text,
        ),
      ];

      final stats = StatisticsEngine.calculate(messages);

      expect(stats.totalMessages, 4);
      expect(stats.participantMessages['Alice'], 2);
      expect(stats.participantMessages['Bob'], 2);

      // Double text check: Bob sent msg 2 and msg 3 consecutively
      expect(stats.doubleTexts['Bob'], 1);
      expect(stats.doubleTexts['Alice'], 0);

      // Starters & Enders:
      // Session 1: Started by Alice (msg 1), Bob is ender (msg 3)
      // Session 2: Started by Alice (msg 4, 6 hrs later), Alice is final ender
      expect(stats.conversationStarters['Alice'], 2);
      expect(stats.conversationEnders['Bob'], 1);
      expect(stats.conversationEnders['Alice'], 1);

      // Questions check
      expect(stats.questionCounts['Alice'], 1);
      expect(stats.questionCounts['Bob'], 2);

      // Laugh & Keyword checks
      expect(stats.laughCounts['Alice'], 1);
      expect(stats.keywordCounts['Alice']!['sorry'], 1);
      expect(stats.keywordCounts['Alice']!['love'], 1);
      expect(stats.keywordCounts['Bob']!['thanks'], 1);

      // Emoji checks
      expect(stats.topEmojis.any((e) => e.emoji == '😂' || e.emoji == '❤️'), isTrue);
    });

    test('100,000 Message Benchmark: executes in under 5.0 seconds', () {
      final baseDate = DateTime(2023, 1, 1, 8, 0);
      final List<ParsedMessage> largeChat = List.generate(100000, (index) {
        final isAlice = index % 2 == 0;
        final sender = isAlice ? 'Alice' : 'Bob';
        final senderId = isAlice ? 'alice' : 'bob';
        final timestamp = baseDate.add(Duration(minutes: index * 2));

        return ParsedMessage(
          id: 'msg_$index',
          index: index + 1,
          timestamp: timestamp,
          senderId: senderId,
          senderName: sender,
          content: index % 5 == 0
              ? 'Haha sure, see you soon! 😂❤️'
              : 'What time is the meeting tomorrow? Thanks!',
          type: MessageType.text,
        );
      });

      final stopwatch = Stopwatch()..start();
      final stats = StatisticsEngine.calculate(largeChat);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print('>>> 100,000 Messages benchmark elapsed time: ${elapsedMs}ms');

      expect(stats.totalMessages, 100000);
      expect(stats.participantMessages['Alice'], 50000);
      expect(stats.participantMessages['Bob'], 50000);
      expect(elapsedMs, lessThan(5000), reason: 'Must complete 100k messages in < 5 seconds');
    });
  });
}
