import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../../../core/errors/app_exception.dart';

/// Service to inspect and extract WhatsApp chat text from exported ZIP archives.
class ZipExtractor {
  /// Extracts the chat text from raw ZIP bytes.
  /// Looks for `_chat.txt` first, or any `.txt` file inside the archive.
  static String extractChatText(List<int> zipBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      ArchiveFile? chatFile;

      // First look for iOS/Android standard `_chat.txt`
      for (final file in archive.files) {
        if (file.isFile && file.name.toLowerCase().endsWith('_chat.txt')) {
          chatFile = file;
          break;
        }
      }

      // If not found, look for any .txt file
      if (chatFile == null) {
        for (final file in archive.files) {
          if (file.isFile && file.name.toLowerCase().endsWith('.txt')) {
            chatFile = file;
            break;
          }
        }
      }

      if (chatFile == null) {
        throw const ParsingException(
          'No valid chat text file (_chat.txt) found inside the ZIP archive.',
          code: 'ZIP_NO_CHAT_TXT',
        );
      }

      final content = chatFile.content as List<int>;
      // Try utf-8 decoding first, fallback to latin1 if corrupt
      try {
        return utf8.decode(content);
      } catch (_) {
        return latin1.decode(content);
      }
    } catch (e) {
      if (e is ParsingException) rethrow;
      throw ParsingException(
        'Failed to extract ZIP archive: $e',
        code: 'ZIP_EXTRACTION_FAILED',
        details: e,
      );
    }
  }

  /// Convenience method to extract from a file path.
  static Future<String> extractFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ParsingException('File not found at $filePath', code: 'FILE_NOT_FOUND');
    }
    final bytes = await file.readAsBytes();
    return extractChatText(bytes);
  }
}
