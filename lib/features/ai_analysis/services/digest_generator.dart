import '../../chat_parser/models/parsed_message.dart';
import '../../chat_setup/models/chat_setup_config.dart';
import '../../../core/constants/app_constants.dart';

/// Preprocessed payload ready for the backend Edge Function.
class DigestPayload {
  final Map<String, String> aliasMap; // Original Name -> Alias (e.g. "Alice" -> "User A")
  final Map<String, String> reverseAliasMap; // Alias -> Original Name
  final List<Map<String, dynamic>> compactMessages;
  final int totalSourceMessages;
  final int sampledMessagesCount;
  final int estimatedTokens;

  const DigestPayload({
    required this.aliasMap,
    required this.reverseAliasMap,
    required this.compactMessages,
    required this.totalSourceMessages,
    required this.sampledMessagesCount,
    required this.estimatedTokens,
  });

  Map<String, dynamic> toJson() => {
        'alias_map': aliasMap,
        'compact_messages': compactMessages,
        'total_source_messages': totalSourceMessages,
        'sampled_count': sampledMessagesCount,
        'estimated_tokens': estimatedTokens,
      };
}

/// Preprocesses, anonymizes with neutral aliases, and creates a compact digest of the conversation.
class DigestGenerator {
  /// Transforms raw messages into a privacy-safe, anonymized, compact payload.
  static DigestPayload preparePayload({
    required List<ParsedMessage> messages,
    required ChatSetupConfig config,
    int maxLimit = AppConstants.maxDigestMessages,
  }) {
    // 1. Filter out system messages and media placeholders
    final userMessages = messages.where((m) => m.isUserMessage).toList();

    // 2. Build neutral alias mapping: "User A" (configured user), "User B", "User C"...
    final Map<String, String> aliasMap = {};
    final Map<String, String> reverseAliasMap = {};

    // User is always "User A"
    aliasMap[config.userParticipantName] = 'User A';
    reverseAliasMap['User A'] = config.userParticipantName;

    int letterCode = 66; // 'B'
    for (final msg in userMessages) {
      if (!aliasMap.containsKey(msg.senderName)) {
        final alias = 'User ${String.fromCharCode(letterCode)}';
        aliasMap[msg.senderName] = alias;
        reverseAliasMap[alias] = msg.senderName;
        letterCode++;
      }
    }

    // 3. Smart sampling if conversation exceeds maxLimit
    List<ParsedMessage> sampled = userMessages;
    if (userMessages.length > maxLimit) {
      sampled = _smartSample(userMessages, maxLimit);
    }

    // 4. Compact representations preserving message IDs and relative times
    int totalEstimatedChars = 0;
    final List<Map<String, dynamic>> compactList = [];

    for (final msg in sampled) {
      final senderAlias = aliasMap[msg.senderName] ?? 'User';
      // Format timestamp compactly: MM-dd HH:mm
      final timeStr = msg.timestamp != null
          ? '${msg.timestamp!.month.toString().padLeft(2, '0')}-${msg.timestamp!.day.toString().padLeft(2, '0')} ${msg.timestamp!.hour.toString().padLeft(2, '0')}:${msg.timestamp!.minute.toString().padLeft(2, '0')}'
          : '';

      // Limit individual message length in digest to 280 chars to avoid prompt bloat
      final content = msg.content.length > 280
          ? '${msg.content.substring(0, 280)}...'
          : msg.content;

      totalEstimatedChars += content.length + 30;

      compactList.add({
        'id': msg.id,
        'u': senderAlias,
        't': timeStr,
        'c': content,
      });
    }

    // 4 chars roughly equals 1 token for multilingual text
    final estimatedTokens = (totalEstimatedChars / 4).ceil();

    return DigestPayload(
      aliasMap: aliasMap,
      reverseAliasMap: reverseAliasMap,
      compactMessages: compactList,
      totalSourceMessages: userMessages.length,
      sampledMessagesCount: compactList.length,
      estimatedTokens: estimatedTokens,
    );
  }

  /// Intelligently samples messages to capture:
  /// - Early conversation initiation (first 15%)
  /// - Middle key interactions (50% sampled evenly)
  /// - Most recent climax exchanges (last 35%)
  static List<ParsedMessage> _smartSample(List<ParsedMessage> list, int limit) {
    if (list.length <= limit) return list;

    final earlyCount = (limit * 0.15).toInt();
    final lateCount = (limit * 0.35).toInt();
    final midCount = limit - earlyCount - lateCount;

    final earlyMessages = list.take(earlyCount).toList();
    final lateMessages = list.skip(list.length - lateCount).toList();

    // Stride through the middle section
    final middleSource = list.sublist(earlyCount, list.length - lateCount);
    final List<ParsedMessage> midMessages = [];
    final double stride = middleSource.length / midCount;

    for (int i = 0; i < midCount; i++) {
      final idx = (i * stride).floor().clamp(0, middleSource.length - 1);
      midMessages.add(middleSource[idx]);
    }

    return [...earlyMessages, ...midMessages, ...lateMessages];
  }
}
