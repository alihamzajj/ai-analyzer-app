import 'package:flutter/foundation.dart';

/// Privacy-safe analytics service.
/// Strictly logs coarse operational metrics.
/// NEVER logs chat messages, personal names, receipts, or raw exceptions.
class AnalyticsService {
  static void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    final sanitizedParams = _sanitizeParams(parameters);
    if (kDebugMode) {
      debugPrint('[Analytics] Event: $eventName -> $sanitizedParams');
    }
    // Forward to backend analytics provider if configured
  }

  static Map<String, dynamic> _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return {};

    final Map<String, dynamic> safe = {};
    for (final entry in params.entries) {
      // Allow only numbers, booleans, and sanitized category keys
      final val = entry.value;
      if (val is num || val is bool) {
        safe[entry.key] = val;
      } else if (val is String) {
        // Only allow predefined enum-like strings, no free-form text
        if (entry.key == 'size_bucket' ||
            entry.key == 'relationship_type' ||
            entry.key == 'error_category' ||
            entry.key == 'roast_intensity' ||
            entry.key == 'language') {
          safe[entry.key] = val;
        }
      }
    }
    return safe;
  }

  /// Calculates coarse message size buckets to preserve privacy.
  static String getCoarseSizeBucket(int messageCount) {
    if (messageCount < 500) return 'under_500';
    if (messageCount < 2000) return '500_to_2k';
    if (messageCount < 10000) return '2k_to_10k';
    if (messageCount < 50000) return '10k_to_50k';
    return '50k_plus';
  }
}
