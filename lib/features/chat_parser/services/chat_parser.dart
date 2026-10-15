import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/chat_metadata.dart';
import '../models/message_type.dart';
import '../models/parsed_message.dart';
import '../models/parse_result.dart';
import 'date_time_parser.dart';
import '../../../core/errors/app_exception.dart';

/// High-performance, robust WhatsApp chat export parser.
/// Handles Android, iOS, 12h/24h, multiline, RTL, system messages, and media placeholders.
class ChatParser {
  // Regex for Android format: "dd/MM/yy, HH:mm - Sender: Message" or "dd/MM/yy, HH:mm - System message"
  static final RegExp _androidHeaderRegex = RegExp(
    r'^(\d{1,4}[./\-]\d{1,4}[./\-]\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s*[aApP]\.?[mM]\.?)?)\s*-\s*(.*)$',
  );

  // Regex for iOS format: "[dd/MM/yy, HH:mm:ss] Sender: Message" or "[dd/MM/yy, HH:mm:ss] System message"
  static final RegExp _iosHeaderRegex = RegExp(
    r'^\[(\d{1,4}[./\-]\d{1,4}[./\-]\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s*[aApP]\.?[mM]\.?)?)\]\s*(.*)$',
  );

  // Media placeholder patterns across languages
  static final List<RegExp> _mediaPatterns = [
    RegExp(r'<Media omitted>', caseSensitive: false),
    RegExp(r'<image omitted>', caseSensitive: false),
    RegExp(r'<video omitted>', caseSensitive: false),
    RegExp(r'<audio omitted>', caseSensitive: false),
    RegExp(r'<sticker omitted>', caseSensitive: false),
    RegExp(r'<document omitted>', caseSensitive: false),
    RegExp(r'<Contact card omitted>', caseSensitive: false),
    RegExp(r'\b(?:image|video|audio|sticker|document|gif)\s+omitted\b', caseSensitive: false),
    RegExp(r'\(file attached\)', caseSensitive: false),
    RegExp(r'<(?:Fichier|Médias|Bild|Audio|Video|Sticker)\s+omitted>', caseSensitive: false),
  ];

  // Deleted message patterns
  static final List<RegExp> _deletedPatterns = [
    RegExp(r'This message was deleted', caseSensitive: false),
    RegExp(r'You deleted this message', caseSensitive: false),
    RegExp(r'Este mensaje fue eliminado', caseSensitive: false),
    RegExp(r'Ce message a été supprimé', caseSensitive: false),
    RegExp(r'Diese Nachricht wurde gelöscht', caseSensitive: false),
    RegExp(r'Questa messaggio è stato cancellato', caseSensitive: false),
    RegExp(r'تم حذف هذه الرسالة', caseSensitive: false),
  ];

  // System notification patterns
  static final List<RegExp> _systemPatterns = [
    RegExp(r'Messages and calls are end-to-end encrypted', caseSensitive: false),
    RegExp(r'created group', caseSensitive: false),
    RegExp(r'added', caseSensitive: false),
    RegExp(r'left', caseSensitive: false),
    RegExp(r'removed', caseSensitive: false),
    RegExp(r'joined using this group', caseSensitive: false),
    RegExp(r'changed the subject to', caseSensitive: false),
    RegExp(r'changed this group', caseSensitive: false),
    RegExp(r'security code changed', caseSensitive: false),
    RegExp(r'changed their phone number', caseSensitive: false),
    RegExp(r'disappearing messages', caseSensitive: false),
    RegExp(r'Les messages et les appels sont chiffrés', caseSensitive: false),
    RegExp(r'Nachrichten und Anrufe sind Ende-zu-Ende-verschlüsselt', caseSensitive: false),
    RegExp(r'Las llamadas y mensajes están cifrados', caseSensitive: false),
  ];

  /// Parses raw chat text into a structured ParseResult.
  static ParseResult parse(String rawContent) {
    final stopwatch = Stopwatch()..start();

    if (rawContent.trim().isEmpty) {
      throw const ParsingException(
        'The imported file is empty.',
        code: 'EMPTY_CHAT_FILE',
      );
    }

    // Split into lines preserving LF/CRLF
    final rawLines = const LineSplitter().convert(rawContent);
    if (rawLines.isEmpty) {
      throw const ParsingException(
        'No readable lines found in the chat file.',
        code: 'NO_LINES_FOUND',
      );
    }

    // Generate a deterministic conversation hash based on the first 1000 characters
    final seedContent = rawContent.length > 2000 ? rawContent.substring(0, 2000) : rawContent;
    final conversationHash = md5.convert(utf8.encode(seedContent)).toString().substring(0, 12);

    // Detect day-first vs month-first date order across the chat
    final isDayFirst = DateTimeParser.detectDayFirst(rawLines);

    final List<ParsedMessage> messages = [];
    final List<String> warnings = [];

    // Working variables for multiline accumulation
    _RawMessageCandidate? currentCandidate;

    void commitCurrentCandidate() {
      if (currentCandidate == null) return;

      final index = messages.length + 1;
      final rawSender = currentCandidate!.sender.trim();
      final text = currentCandidate!.body.toString().trim();
      final dt = currentCandidate!.timestamp;

      // Classify message type
      MessageType type = MessageType.text;
      String finalSender = rawSender;

      if (rawSender.isEmpty || currentCandidate!.isSystem) {
        type = MessageType.system;
        finalSender = 'System';
      } else if (_isMediaMessage(text)) {
        type = MessageType.media;
      } else if (_isDeletedMessage(text)) {
        type = MessageType.deleted;
      } else if (_isSystemMessage(text)) {
        type = MessageType.system;
      }

      // Generate stable, unique message ID
      final idSeed = '$conversationHash:$index:${dt?.millisecondsSinceEpoch ?? 0}:$finalSender:${text.length > 30 ? text.substring(0, 30) : text}';
      final messageId = 'msg_${sha256.convert(utf8.encode(idSeed)).toString().substring(0, 16)}';

      final senderId = _normalizeSenderId(finalSender);

      messages.add(
        ParsedMessage(
          id: messageId,
          index: index,
          timestamp: dt,
          senderId: senderId,
          senderName: finalSender,
          content: text,
          type: type,
        ),
      );

      currentCandidate = null;
    }

    for (int i = 0; i < rawLines.length; i++) {
      final rawLine = rawLines[i];
      final line = DateTimeParser.cleanUnicodeMarks(rawLine);

      if (line.trim().isEmpty && currentCandidate == null) {
        continue;
      }

      // Try matching iOS format first, then Android format
      var match = _iosHeaderRegex.firstMatch(line) ?? _androidHeaderRegex.firstMatch(line);

      if (match != null) {
        // We found a new message header! Commit any previous accumulated candidate
        commitCurrentCandidate();

        final rawDate = match.group(1)!;
        final rawTime = match.group(2)!;
        final remainder = match.group(3)!;

        final timestamp = DateTimeParser.parseDateTime(
          rawDate,
          rawTime,
          isDayFirst: isDayFirst,
        );

        if (timestamp == null && warnings.length < 5) {
          warnings.add('Unable to parse timestamp on line ${i + 1}: "$rawDate $rawTime"');
        }

        // Check if remainder has "Sender: Message" or is a system announcement
        final colonIndex = remainder.indexOf(':');

        if (colonIndex != -1) {
          // Check if sender looks like a legitimate name (doesn't contain typical system phrasing)
          final possibleSender = remainder.substring(0, colonIndex).trim();
          final possibleBody = remainder.substring(colonIndex + 1).trim();

          currentCandidate = _RawMessageCandidate(
            timestamp: timestamp,
            sender: possibleSender,
            isSystem: false,
          )..body.write(possibleBody);
        } else {
          // System message without a sender
          currentCandidate = _RawMessageCandidate(
            timestamp: timestamp,
            sender: 'System',
            isSystem: true,
          )..body.write(remainder.trim());
        }
      } else {
        // Continuation line of a multiline message
        if (currentCandidate != null) {
          if (currentCandidate!.body.isNotEmpty) {
            currentCandidate!.body.write('\n');
          }
          currentCandidate!.body.write(rawLine);
        }
      }
    }

    // Commit any final trailing candidate
    commitCurrentCandidate();

    stopwatch.stop();

    if (messages.isEmpty) {
      throw const ParsingException(
        'Could not parse any valid messages from the chat export. Check that this is an official WhatsApp export.',
        code: 'PARSER_NO_MATCHES',
      );
    }

    // Calculate metadata
    final metadata = _buildMetadata(messages, warnings);

    return ParseResult(
      messages: messages,
      metadata: metadata,
      conversationHash: conversationHash,
      parsingTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  static bool _isMediaMessage(String text) {
    for (final pattern in _mediaPatterns) {
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }

  static bool _isDeletedMessage(String text) {
    for (final pattern in _deletedPatterns) {
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }

  static bool _isSystemMessage(String text) {
    for (final pattern in _systemPatterns) {
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }

  static String _normalizeSenderId(String sender) {
    if (sender == 'System') return 'system';
    return sender.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  static ChatMetadata _buildMetadata(
    List<ParsedMessage> messages,
    List<String> warnings,
  ) {
    final Map<String, int> msgCounts = {};
    final Map<String, int> mediaCounts = {};
    int totalMedia = 0;
    int totalDeleted = 0;
    int totalSystem = 0;
    DateTime? start;
    DateTime? end;

    for (final msg in messages) {
      if (msg.timestamp != null) {
        start = start == null
            ? msg.timestamp
            : (msg.timestamp!.isBefore(start) ? msg.timestamp : start);
        end = end == null
            ? msg.timestamp
            : (msg.timestamp!.isAfter(end) ? msg.timestamp : end);
      }

      if (msg.isSystem) {
        totalSystem++;
        continue;
      }

      if (msg.isDeleted) {
        totalDeleted++;
      }

      if (msg.isMedia) {
        totalMedia++;
        mediaCounts[msg.senderName] = (mediaCounts[msg.senderName] ?? 0) + 1;
      }

      if (msg.isUserMessage) {
        msgCounts[msg.senderName] = (msgCounts[msg.senderName] ?? 0) + 1;
      }
    }

    final participants = msgCounts.keys.toList();

    return ChatMetadata(
      participants: participants,
      messageCountByParticipant: msgCounts,
      mediaCountByParticipant: mediaCounts,
      totalMessages: messages.length,
      totalMedia: totalMedia,
      totalDeleted: totalDeleted,
      totalSystem: totalSystem,
      startDate: start,
      endDate: end,
      warnings: warnings,
    );
  }
}

class _RawMessageCandidate {
  final DateTime? timestamp;
  final String sender;
  final bool isSystem;
  final StringBuffer body = StringBuffer();

  _RawMessageCandidate({
    required this.timestamp,
    required this.sender,
    required this.isSystem,
  });
}
