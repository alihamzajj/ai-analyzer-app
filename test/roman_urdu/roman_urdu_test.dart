import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_analyser/core/utils/roman_urdu.dart';
import 'package:ai_chat_analyser/features/chat_parser/models/message_type.dart';
import 'package:ai_chat_analyser/features/chat_parser/models/parsed_message.dart';
import 'package:ai_chat_analyser/features/statistics/services/statistics_engine.dart';

ParsedMessage _msg(int i, String sender, String text, {int minutes = 0}) => ParsedMessage(
      id: '$i',
      index: i,
      timestamp: DateTime(2026, 5, 1, 21).add(Duration(minutes: minutes)),
      senderId: sender.toLowerCase(),
      senderName: sender,
      content: text,
      type: MessageType.text,
    );

void main() {
  group('Roman Urdu detection', () {
    test('detects a typical Roman Urdu chat', () {
      const chat = [
        'kya kar rahe ho',
        'kuch nahi yaar bas baitha hun',
        'acha theek hai, khana khaya?',
        'han kha liya, tum batao',
        'main bhi bas abhi free hui hun',
      ];
      expect(RomanUrdu.isMostlyRomanUrdu(chat), isTrue);
    });

    test('does not flag an English chat', () {
      const chat = [
        'what are you doing tonight',
        'nothing much, just watching a movie',
        'want to grab coffee tomorrow?',
        'sure, see you at 5',
        'perfect, can not wait',
      ];
      expect(RomanUrdu.isMostlyRomanUrdu(chat), isFalse);
    });
  });

  group('StatisticsEngine with Roman Urdu', () {
    final messages = [
      _msg(1, 'Ali', 'kya kar rahe ho'),
      _msg(2, 'Sara', 'kuch nahi yaar hahaha', minutes: 3),
      _msg(3, 'Ali', 'kal milo ge kahan', minutes: 5),
      _msg(4, 'Sara', 'shukriya yaad rakhne ka', minutes: 9),
      _msg(5, 'Ali', 'maaf karna late reply, bohat pyar biryani se', minutes: 15),
      _msg(6, 'Sara', 'gn, so jao ab', minutes: 20),
      _msg(7, 'Ali', 'biryani biryani', minutes: 21),
    ];
    final stats = StatisticsEngine.calculate(messages);

    test('counts questions written without a question mark', () {
      expect(stats.questionCounts['Ali'], 2);
      expect(stats.questionCounts['Sara'], 0);
    });

    test('counts Roman Urdu laughter', () {
      expect(stats.laughCounts['Sara'], 1);
    });

    test('maps Roman Urdu keywords to the same buckets', () {
      expect(stats.keywordCounts['Sara']!['thanks'], 1);
      expect(stats.keywordCounts['Ali']!['sorry'], 1);
      expect(stats.keywordCounts['Ali']!['love'], 1);
      expect(stats.keywordCounts['Sara']!['goodnight'], 1);
    });

    test('keeps filler words like hai / nahi / yaar out of top words', () {
      final top = stats.topWords.map((w) => w.word).toList();
      expect(top.first, 'biryani');
      for (final filler in ['nahi', 'yaar', 'kya', 'rahe', 'kuch']) {
        expect(top.contains(filler), isFalse, reason: '$filler should be filtered');
      }
    });

    test('short keywords only match whole words', () {
      final s = StatisticsEngine.calculate([_msg(1, 'Ali', 'sign the agreement please')]);
      expect(s.keywordCounts['Ali']!['goodnight'], 0);
    });
  });
}
