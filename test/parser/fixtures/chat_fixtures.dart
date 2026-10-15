/// Synthetic WhatsApp chat export fixtures for testing the parser.
/// Contains no real private conversations.
class ChatFixtures {
  /// 1. Android 24-hour standard
  static const String android24h = '''
12/03/23, 09:15 - Alex: Morning! Are we still meeting today?
12/03/23, 09:16 - Jordan: Yes, definitely! 1pm at the cafe?
12/03/23, 09:18 - Alex: Perfect. See you there.
''';

  /// 2. Android 12-hour AM/PM with standard space
  static const String android12h = '''
12/03/2023, 9:15 am - Alex: Morning! Are we still meeting today?
12/03/2023, 1:16 pm - Jordan: Yes, definitely! 1pm at the cafe?
12/03/2023, 1:18 pm - Alex: Perfect. See you there.
''';

  /// 3. Android 12-hour with U+202F Narrow No-Break Space
  static const String androidNarrowNoBreakSpace =
      '12/03/2023, 9:15\u202fam - Alex: Morning!\n'
      '12/03/2023, 1:16\u202fpm - Jordan: Sounds good.\n';

  /// 4. Android with U+200E Left-to-Right Mark at line start
  static const String androidUnicodeLrm =
      '\u200E12/03/2023, 09:15 - Alex: Hello with LRM!\n'
      '\u200E12/03/2023, 09:16 - Jordan: Replying with LRM.\n';

  /// 5. Android Month-first format (MM/dd/yy with day 25 > 12)
  static const String androidMonthFirst = '''
03/25/23, 14:10 - Taylor: Hey, the party is today!
03/25/23, 14:12 - Sam: Awesome, bringing drinks now.
''';

  /// 6. Android with dashes in dates (yyyy-MM-dd)
  static const String androidIsoDashes = '''
2023-08-15, 14:22 - Alice: Meeting starts now.
2023-08-15, 14:23 - Bob: Joining the call.
''';

  /// 7. Android with dots in dates (dd.MM.yy)
  static const String androidDotsInDate = '''
15.08.23, 14:22 - Sarah: Look at this document.
15.08.23, 14:25 - Mike: Received, reviewing now.
''';

  /// 8. Android multiline messages
  static const String androidMultiline = '''
12/03/23, 10:00 - Alex: Here is the plan:
Step 1: Grab groceries
Step 2: Cook dinner
Step 3: Watch movie
12/03/23, 10:05 - Jordan: Sounds like a solid plan!
''';

  /// 9. Android with colons and URLs in message body
  static const String androidColonsAndUrls = '''
12/03/23, 10:00 - Alex: Note: check this out: https://example.com/item:42
12/03/23, 10:01 - Jordan: Wow, that's fast: 10/10!
''';

  /// 10. Android system encryption and group join notices
  static const String androidSystemMessages = '''
12/03/23, 09:00 - Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them.
12/03/23, 09:01 - Alex created group "Project X"
12/03/23, 09:02 - Alex added Jordan
12/03/23, 09:05 - Alex: Welcome to the group!
12/03/23, 09:06 - Jordan: Thanks Alex!
''';

  /// 11. Android media omitted placeholders
  static const String androidMediaOmitted = '''
12/03/23, 11:00 - Alex: Check out this photo!
12/03/23, 11:00 - Alex: <Media omitted>
12/03/23, 11:01 - Jordan: <image omitted>
12/03/23, 11:02 - Alex: Haha nice!
''';

  /// 12. Android deleted messages
  static const String androidDeletedMessages = '''
12/03/23, 12:00 - Alex: Oops sent to wrong chat
12/03/23, 12:01 - Alex: This message was deleted
12/03/23, 12:02 - Jordan: What was it? 😂
''';

  /// 13. iOS standard bracketed format
  static const String iosStandard24h = '''
[12/03/23, 14:30:15] Emma: Hey, are you free tonight?
[12/03/23, 14:31:02] Liam: Yes, totally! What did you have in mind?
[12/03/23, 14:32:45] Emma: Dinner downtown?
''';

  /// 14. iOS 12-hour AM/PM bracketed
  static const String ios12hAmPm = '''
[12/03/2023, 2:30:15 PM] Emma: Hey, are you free tonight?
[12/03/2023, 2:31:02 PM] Liam: Yes, totally!
[12/03/2023, 2:32:45 PM] Emma: Let's do it!
''';

  /// 15. iOS Month-first format (M/d/yy with day 26 > 12)
  static const String iosMonthFirst = '''
[3/26/23, 7:15:00 PM] Chris: Game starts in 10 minutes!
[3/26/23, 7:16:30 PM] Morgan: Tuning in right now!
''';

  /// 16. iOS multiline message with blank lines
  static const String iosMultiline = '''
[12/03/23, 15:00:00] Emma: Hey!

Just wanted to check if you got the tickets?
[12/03/23, 15:02:10] Liam: Yes, got both in my email!
''';

  /// 17. iOS system messages
  static const String iosSystemMessages = '''
[12/03/23, 08:00:00] Messages and calls are end-to-end encrypted.
[12/03/23, 08:05:00] Emma: Good morning!
[12/03/23, 08:06:00] Liam: Morning Emma!
''';

  /// 18. Multilingual Spanish export
  static const String spanishExport = '''
15/04/23, 18:20 - Carlos: ¡Hola Sofía! ¿Cómo vas con el proyecto?
15/04/23, 18:22 - Sofía: Hola Carlos! Casi terminado, te lo paso en un rato.
15/04/23, 18:23 - Carlos: Buenísimo, muchas gracias.
''';

  /// 19. Multilingual French export
  static const String frenchExport = '''
15/05/2023, 09:15 - Amélie: Bonjour! Tu viens à la réunion ce matin?
15/05/2023, 09:16 - Julien: Oui, j'arrive dans 5 minutes.
15/05/2023, 09:17 - Amélie: Parfait, à tout de suite!
''';

  /// 20. Multilingual German export
  static const String germanExport = '''
20.06.23, 18:45 - Lukas: Hallo! Gehen wir heute Abend noch ins Kino?
20.06.23, 18:47 - Hannah: Ja gerne! Welcher Film läuft denn?
20.06.23, 18:50 - Lukas: Der neue Sci-Fi Film um 20 Uhr.
''';

  /// 21. Arabic RTL export with Unicode characters
  static const String arabicExport = '''
10/01/2023, 12:00 - أحمد: مرحبا كيف حالك اليوم؟
10/01/2023, 12:01 - فاطمة: الحمد لله بخير، كيف كان يومك؟
10/01/2023, 12:03 - أحمد: يوم ممتاز ومليء بالإنجازات.
''';

  /// 22. Group chat with 4 participants
  static const String groupChat = '''
14/02/23, 19:00 - Dave: Who is ready for trivia night?
14/02/23, 19:01 - Sarah: Me! We are winning this time.
14/02/23, 19:02 - Leo: Count me in too.
14/02/23, 19:03 - Maya: I might be 10 minutes late, save me a seat!
14/02/23, 19:04 - Dave: Got it Maya!
''';
}
