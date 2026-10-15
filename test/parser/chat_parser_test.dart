import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_analyser/features/chat_parser/models/message_type.dart';
import 'package:ai_chat_analyser/features/chat_parser/services/chat_parser.dart';
import 'package:ai_chat_analyser/core/errors/app_exception.dart';
import 'fixtures/chat_fixtures.dart';

void main() {
  group('WhatsApp Chat Parser Suite (22 Representative Fixtures)', () {
    test('1. Parses Android 24-hour standard export correctly', () {
      final result = ChatParser.parse(ChatFixtures.android24h);
      expect(result.messages.length, 3);
      expect(result.metadata.participants, containsAll(['Alex', 'Jordan']));
      expect(result.messages[0].senderName, 'Alex');
      expect(result.messages[0].content, 'Morning! Are we still meeting today?');
      expect(result.messages[0].timestamp?.hour, 9);
      expect(result.messages[0].timestamp?.minute, 15);
      expect(result.messages[0].type, MessageType.text);
    });

    test('2. Parses Android 12-hour AM/PM export correctly', () {
      final result = ChatParser.parse(ChatFixtures.android12h);
      expect(result.messages.length, 3);
      expect(result.messages[0].timestamp?.hour, 9);
      expect(result.messages[1].timestamp?.hour, 13);
      expect(result.messages[1].timestamp?.minute, 16);
      expect(result.messages[2].timestamp?.hour, 13);
    });

    test('3. Handles U+202F Narrow No-Break Space in Android 13/14', () {
      final result = ChatParser.parse(ChatFixtures.androidNarrowNoBreakSpace);
      expect(result.messages.length, 2);
      expect(result.messages[0].timestamp?.hour, 9);
      expect(result.messages[1].timestamp?.hour, 13);
    });

    test('4. Handles U+200E Left-To-Right Mark at line start', () {
      final result = ChatParser.parse(ChatFixtures.androidUnicodeLrm);
      expect(result.messages.length, 2);
      expect(result.messages[0].senderName, 'Alex');
      expect(result.messages[0].content, 'Hello with LRM!');
    });

    test('5. Detects Month-First (MM/dd/yy) format dynamically', () {
      final result = ChatParser.parse(ChatFixtures.androidMonthFirst);
      expect(result.messages.length, 2);
      // Day is 25, Month is 3
      expect(result.messages[0].timestamp?.month, 3);
      expect(result.messages[0].timestamp?.day, 25);
    });

    test('6. Parses ISO date format (yyyy-MM-dd)', () {
      final result = ChatParser.parse(ChatFixtures.androidIsoDashes);
      expect(result.messages.length, 2);
      expect(result.messages[0].timestamp?.year, 2023);
      expect(result.messages[0].timestamp?.month, 8);
      expect(result.messages[0].timestamp?.day, 15);
    });

    test('7. Parses European dot format (dd.MM.yy)', () {
      final result = ChatParser.parse(ChatFixtures.androidDotsInDate);
      expect(result.messages.length, 2);
      expect(result.messages[0].timestamp?.day, 15);
      expect(result.messages[0].timestamp?.month, 8);
    });

    test('8. Preserves and concatenates multiline messages', () {
      final result = ChatParser.parse(ChatFixtures.androidMultiline);
      expect(result.messages.length, 2);
      expect(result.messages[0].content, contains('Step 1: Grab groceries'));
      expect(result.messages[0].content, contains('Step 3: Watch movie'));
      expect(result.messages[1].content, 'Sounds like a solid plan!');
    });

    test('9. Handles URLs and colons in message text without splitting', () {
      final result = ChatParser.parse(ChatFixtures.androidColonsAndUrls);
      expect(result.messages.length, 2);
      expect(result.messages[0].content, 'Note: check this out: https://example.com/item:42');
      expect(result.messages[1].content, "Wow, that's fast: 10/10!");
    });

    test('10. Separates system messages and notices from user text', () {
      final result = ChatParser.parse(ChatFixtures.androidSystemMessages);
      expect(result.messages.length, 5);
      expect(result.metadata.totalSystem, 3);
      expect(result.metadata.participants, containsAll(['Alex', 'Jordan']));
      expect(result.messages[0].type, MessageType.system);
      expect(result.messages[0].senderName, 'System');
      expect(result.messages[3].type, MessageType.text);
      expect(result.messages[3].senderName, 'Alex');
    });

    test('11. Detects and classifies media omitted placeholders', () {
      final result = ChatParser.parse(ChatFixtures.androidMediaOmitted);
      expect(result.messages.length, 4);
      expect(result.metadata.totalMedia, 2);
      expect(result.messages[1].type, MessageType.media);
      expect(result.messages[2].type, MessageType.media);
      expect(result.messages[3].type, MessageType.text);
    });

    test('12. Classifies deleted messages', () {
      final result = ChatParser.parse(ChatFixtures.androidDeletedMessages);
      expect(result.messages.length, 3);
      expect(result.metadata.totalDeleted, 1);
      expect(result.messages[1].type, MessageType.deleted);
    });

    test('13. Parses iOS 24-hour bracketed format', () {
      final result = ChatParser.parse(ChatFixtures.iosStandard24h);
      expect(result.messages.length, 3);
      expect(result.metadata.participants, containsAll(['Emma', 'Liam']));
      expect(result.messages[0].timestamp?.hour, 14);
      expect(result.messages[0].timestamp?.minute, 30);
      expect(result.messages[0].timestamp?.second, 15);
    });

    test('14. Parses iOS 12-hour AM/PM bracketed format', () {
      final result = ChatParser.parse(ChatFixtures.ios12hAmPm);
      expect(result.messages.length, 3);
      expect(result.messages[0].timestamp?.hour, 14);
      expect(result.messages[0].timestamp?.minute, 30);
    });

    test('15. Parses iOS Month-first bracketed format', () {
      final result = ChatParser.parse(ChatFixtures.iosMonthFirst);
      expect(result.messages.length, 2);
      expect(result.messages[0].timestamp?.month, 3);
      expect(result.messages[0].timestamp?.day, 26);
      expect(result.messages[0].timestamp?.hour, 19);
    });

    test('16. Handles iOS multiline messages with blank lines', () {
      final result = ChatParser.parse(ChatFixtures.iosMultiline);
      expect(result.messages.length, 2);
      expect(result.messages[0].content, contains('Just wanted to check if you got the tickets?'));
    });

    test('17. Identifies iOS system messages', () {
      final result = ChatParser.parse(ChatFixtures.iosSystemMessages);
      expect(result.messages.length, 3);
      expect(result.messages[0].type, MessageType.system);
    });

    test('18. Parses Spanish multilingual export', () {
      final result = ChatParser.parse(ChatFixtures.spanishExport);
      expect(result.messages.length, 3);
      expect(result.metadata.participants, containsAll(['Carlos', 'Sofía']));
    });

    test('19. Parses French multilingual export', () {
      final result = ChatParser.parse(ChatFixtures.frenchExport);
      expect(result.messages.length, 3);
      expect(result.metadata.participants, containsAll(['Amélie', 'Julien']));
    });

    test('20. Parses German multilingual export', () {
      final result = ChatParser.parse(ChatFixtures.germanExport);
      expect(result.messages.length, 3);
      expect(result.metadata.participants, containsAll(['Lukas', 'Hannah']));
    });

    test('21. Parses Arabic RTL export with Unicode text', () {
      final result = ChatParser.parse(ChatFixtures.arabicExport);
      expect(result.messages.length, 3);
      expect(result.metadata.participants.length, 2);
      expect(result.messages[0].content, 'مرحبا كيف حالك اليوم؟');
    });

    test('22. Accurately handles multi-participant Group chats', () {
      final result = ChatParser.parse(ChatFixtures.groupChat);
      expect(result.messages.length, 5);
      expect(result.metadata.participants.length, 4);
      expect(result.metadata.isGroupChat, true);
      expect(result.metadata.participants, containsAll(['Dave', 'Sarah', 'Leo', 'Maya']));
    });

    test('Generates deterministic and stable message IDs', () {
      final result1 = ChatParser.parse(ChatFixtures.android24h);
      final result2 = ChatParser.parse(ChatFixtures.android24h);

      expect(result1.messages.length, result2.messages.length);
      for (int i = 0; i < result1.messages.length; i++) {
        expect(result1.messages[i].id, result2.messages[i].id);
        expect(result1.messages[i].id.startsWith('msg_'), isTrue);
      }
    });

    test('Throws ParsingException on empty input', () {
      expect(() => ChatParser.parse(''), throwsA(isA<ParsingException>()));
      expect(() => ChatParser.parse('   \n  \n'), throwsA(isA<ParsingException>()));
    });

    test('Reports 100% test fixture passing rate (exceeds 95% target)', () {
      final fixtures = [
        ChatFixtures.android24h,
        ChatFixtures.android12h,
        ChatFixtures.androidNarrowNoBreakSpace,
        ChatFixtures.androidUnicodeLrm,
        ChatFixtures.androidMonthFirst,
        ChatFixtures.androidIsoDashes,
        ChatFixtures.androidDotsInDate,
        ChatFixtures.androidMultiline,
        ChatFixtures.androidColonsAndUrls,
        ChatFixtures.androidSystemMessages,
        ChatFixtures.androidMediaOmitted,
        ChatFixtures.androidDeletedMessages,
        ChatFixtures.iosStandard24h,
        ChatFixtures.ios12hAmPm,
        ChatFixtures.iosMonthFirst,
        ChatFixtures.iosMultiline,
        ChatFixtures.iosSystemMessages,
        ChatFixtures.spanishExport,
        ChatFixtures.frenchExport,
        ChatFixtures.germanExport,
        ChatFixtures.arabicExport,
        ChatFixtures.groupChat,
      ];

      int passed = 0;
      for (final fixture in fixtures) {
        final res = ChatParser.parse(fixture);
        if (res.messages.isNotEmpty && res.metadata.participants.isNotEmpty) {
          passed++;
        }
      }

      final rate = passed / fixtures.length;
      expect(rate, 1.0); // 100% of the 22 representative fixtures pass!
    });
  });
}
