/// Specialized date and time parser for WhatsApp chat exports.
/// Handles Android, iOS, 12h/24h, Unicode marks, and ambiguous date formats.
class DateTimeParser {
  /// Cleans invisible unicode control characters from lines.
  static String cleanUnicodeMarks(String text) {
    return text
        .replaceAll('\u200E', '') // Left-to-right mark (LRM)
        .replaceAll('\u200F', '') // Right-to-left mark (RLM)
        .replaceAll('\u202F', ' ') // Narrow no-break space (Android 13/14 AM/PM)
        .replaceAll('\u00A0', ' ') // Non-breaking space
        .replaceAll('\uFEFF', ''); // Zero-width non-breaking space
  }

  /// Scans the chat lines to deterministically resolve whether the date format is
  /// day-first (dd/mm) or month-first (mm/dd).
  /// Returns `true` if day-first, `false` if month-first.
  static bool detectDayFirst(List<String> rawLines) {
    final datePattern = RegExp(r'(?:^\[?|\b)(\d{1,4})[./\-](\d{1,4})[./\-](\d{2,4})');
    
    int dayFirstEvidence = 0;
    int monthFirstEvidence = 0;

    for (final rawLine in rawLines) {
      final line = cleanUnicodeMarks(rawLine);
      final match = datePattern.firstMatch(line);
      if (match != null) {
        final p1 = int.tryParse(match.group(1)!) ?? 0;
        final p2 = int.tryParse(match.group(2)!) ?? 0;

        // If p1 > 12 and p2 <= 12, p1 must be day -> day-first
        if (p1 > 12 && p2 <= 12) {
          dayFirstEvidence++;
        }
        // If p2 > 12 and p1 <= 12, p2 must be day -> month-first
        else if (p2 > 12 && p1 <= 12) {
          monthFirstEvidence++;
        }
      }

      if (dayFirstEvidence > 5 || monthFirstEvidence > 5) {
        break;
      }
    }

    if (monthFirstEvidence > dayFirstEvidence) {
      return false; // Month-first (MM/dd)
    }
    // Default to day-first (dd/MM) which is standard across Android/iOS international exports
    return true;
  }

  /// Parses a date string and time string into a valid DateTime.
  static DateTime? parseDateTime(
    String rawDate,
    String rawTime, {
    required bool isDayFirst,
  }) {
    try {
      final cleanedDate = cleanUnicodeMarks(rawDate).trim();
      final cleanedTime = cleanUnicodeMarks(rawTime).trim().toLowerCase();

      // Parse date components: separator can be '/', '.', or '-'
      final dateDelim = RegExp(r'[./\-]');
      final dateParts = cleanedDate.split(dateDelim);
      if (dateParts.length != 3) return null;

      int day;
      int month;
      int year;

      final p1 = int.parse(dateParts[0]);
      final p2 = int.parse(dateParts[1]);
      final p3 = int.parse(dateParts[2]);

      // Check if p1 is a 4-digit year (e.g. 2023-05-12)
      if (p1 > 1000) {
        year = p1;
        month = p2;
        day = p3;
      } else {
        // p3 is year
        year = p3 < 100 ? 2000 + p3 : p3;
        if (isDayFirst) {
          day = p1;
          month = p2;
        } else {
          month = p1;
          day = p2;
        }
      }

      // Parse time components
      // Example formats: "14:30", "2:30 pm", "14:30:15", "02:30:15 PM"
      final isPm = cleanedTime.contains('pm') || cleanedTime.contains('p.m.');
      final isAm = cleanedTime.contains('am') || cleanedTime.contains('a.m.');

      final timeOnly = cleanedTime
          .replaceAll(RegExp(r'[a-z.\s]'), '')
          .trim();
      final timeParts = timeOnly.split(':');
      if (timeParts.isEmpty) return null;

      int hour = int.parse(timeParts[0]);
      final int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      final int second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      if (isPm && hour < 12) {
        hour += 12;
      } else if (isAm && hour == 12) {
        hour = 0;
      }

      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
}
