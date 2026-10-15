import 'parsed_message.dart';
import 'chat_metadata.dart';
import '../../../core/constants/app_constants.dart';

/// Complete result of parsing a chat export file.
class ParseResult {
  final List<ParsedMessage> messages;
  final ChatMetadata metadata;
  final String conversationHash;
  final int parsingTimeMs;

  const ParseResult({
    required this.messages,
    required this.metadata,
    required this.conversationHash,
    required this.parsingTimeMs,
  });

  bool get isValid =>
      messages.where((m) => m.isUserMessage).length >= AppConstants.minMessagesRequired;

  int get userMessageCount =>
      messages.where((m) => m.isUserMessage).length;
}
