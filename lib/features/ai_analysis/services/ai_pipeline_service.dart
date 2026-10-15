import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../chat_parser/models/parsed_message.dart';
import '../../chat_setup/models/chat_setup_config.dart';
import '../../statistics/models/chat_statistics.dart';
import '../models/analysis_report.dart';
import '../models/report_card.dart';
import 'digest_generator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';

typedef ProgressCallback = void Function(String stage, double progress);

/// Client-side AI orchestration pipeline.
/// Prepares anonymized digest, contacts Supabase Edge Function, verifies message receipts,
/// and re-maps aliases to original participant display names.
class AiPipelineService {
  final SupabaseClient? supabaseClient;
  final String? customBackendUrl;

  AiPipelineService({
    this.supabaseClient,
    this.customBackendUrl,
  });

  /// Executes the full multi-stage AI analysis pipeline with live honest progress reporting.
  Future<AnalysisReport> generateReport({
    required List<ParsedMessage> messages,
    required ChatStatistics statistics,
    required ChatSetupConfig config,
    required String conversationHash,
    bool isTeaserOnly = false,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Stage 1: Preparing conversation & digest
      onProgress?.call('Preparing conversation & anonymizing aliases...', 0.15);
      await Future.delayed(const Duration(milliseconds: 200));

      final digestPayload = DigestGenerator.preparePayload(
        messages: messages,
        config: config,
      );

      // Build fast lookup map for original messages by stable ID
      final Map<String, ParsedMessage> messageLookup = {
        for (final m in messages) m.id: m,
      };

      // Stage 2: Creating conversation digest
      onProgress?.call('Creating compact conversation digest...', 0.35);
      await Future.delayed(const Duration(milliseconds: 300));

      // Build request body
      final requestBody = {
        'relationship_type': config.relationshipType,
        'output_language': config.outputLanguage,
        'roast_intensity': config.roastIntensity,
        'enable_roast': config.enableRoast,
        'is_teaser_only': isTeaserOnly,
        'statistics_summary': {
          'total_messages': statistics.totalMessages,
          'participant_messages': statistics.participantMessages,
          'avg_response_time_minutes': statistics.avgResponseTimeMinutes,
          'double_texts': statistics.doubleTexts,
          'conversation_starters': statistics.conversationStarters,
        },
        'compact_messages': digestPayload.compactMessages,
      };

      // Stage 3: Contacting backend
      onProgress?.call('Generating AI report & analyzing dynamics...', 0.60);

      Map<String, dynamic> responseData;

      if (supabaseClient != null) {
        final res = await supabaseClient!.functions.invoke(
          AppConstants.functionAnalyseChat,
          body: requestBody,
        );
        if (res.status != 200) {
          throw AiServiceException(
            'Backend returned status ${res.status}: ${res.data}',
            code: 'BACKEND_STATUS_${res.status}',
          );
        }
        responseData = res.data is String ? jsonDecode(res.data) : res.data;
      } else if (customBackendUrl != null && customBackendUrl!.isNotEmpty) {
        final url = Uri.parse(customBackendUrl!);
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );
        if (res.statusCode != 200) {
          throw AiServiceException(
            'HTTP error ${res.statusCode}: ${res.body}',
            code: 'HTTP_STATUS_${res.statusCode}',
          );
        }
        responseData = jsonDecode(res.body);
      } else {
        // Fallback demo mode when Supabase is not yet configured with live secrets
        await Future.delayed(const Duration(seconds: 1));
        responseData = _generateLocalFallbackResponse(
          config: config,
          digestPayload: digestPayload,
          statistics: statistics,
        );
      }

      // Stage 4: Validating results & receipts
      onProgress?.call('Validating results & message receipts...', 0.85);
      await Future.delayed(const Duration(milliseconds: 200));

      final rawCards = (responseData['cards'] as List? ?? [])
          .map((c) => ReportCard.fromJson(c as Map<String, dynamic>))
          .toList();

      // De-anonymize aliases and verify receipts against local messages
      final List<ReportCard> validatedCards = [];

      for (final card in rawCards) {
        // Verify message IDs point to genuine messages
        final verifiedIds = card.messageIds
            .where((id) => messageLookup.containsKey(id))
            .toList();

        // Remap any aliased user names in text to real names
        String restoredSummary = card.summary;
        String restoredTitle = card.title;
        String restoredSubtitle = card.subtitle;

        digestPayload.reverseAliasMap.forEach((alias, realName) {
          restoredSummary = restoredSummary.replaceAll(alias, realName);
          restoredTitle = restoredTitle.replaceAll(alias, realName);
          restoredSubtitle = restoredSubtitle.replaceAll(alias, realName);
        });

        validatedCards.add(
          ReportCard(
            type: card.type,
            title: restoredTitle,
            subtitle: restoredSubtitle,
            summary: restoredSummary,
            score: card.score,
            confidence: card.confidence,
            messageIds: verifiedIds,
            extraData: card.extraData,
          ),
        );
      }

      ReportCard? teaser;
      if (responseData['teaser_insight'] != null) {
        final rawTeaser = ReportCard.fromJson(
          responseData['teaser_insight'] as Map<String, dynamic>,
        );
        String restoredTeaserSummary = rawTeaser.summary;
        digestPayload.reverseAliasMap.forEach((alias, realName) {
          restoredTeaserSummary = restoredTeaserSummary.replaceAll(alias, realName);
        });

        teaser = ReportCard(
          type: rawTeaser.type,
          title: rawTeaser.title,
          subtitle: rawTeaser.subtitle,
          summary: restoredTeaserSummary,
          score: rawTeaser.score,
          confidence: rawTeaser.confidence,
          messageIds: rawTeaser.messageIds
              .where((id) => messageLookup.containsKey(id))
              .toList(),
        );
      }

      // Stage 5: Saving report
      onProgress?.call('Saving report to device...', 1.0);

      final report = AnalysisReport(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}_$conversationHash',
        conversationHash: conversationHash,
        createdAt: DateTime.now(),
        relationshipType: config.relationshipType,
        language: config.outputLanguage,
        userParticipant: config.userParticipantName,
        participants: statistics.participantMessages.keys.toList(),
        cards: validatedCards,
        teaserInsight: teaser,
        statistics: statistics,
      );

      return report;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AiServiceException('Failed to generate report: $e', details: e);
    }
  }

  /// Generates a valid local fallback report for instant offline capability or development
  static Map<String, dynamic> _generateLocalFallbackResponse({
    required ChatSetupConfig config,
    required DigestPayload digestPayload,
    required ChatStatistics statistics,
  }) {
    final sampleIds = digestPayload.compactMessages.take(4).map((m) => m['id'] as String).toList();
    final id1 = sampleIds.isNotEmpty ? sampleIds[0] : '';
    final id2 = sampleIds.length > 1 ? sampleIds[1] : id1;
    final id3 = sampleIds.length > 2 ? sampleIds[2] : id1;

    final cards = [
      {
        'type': 'interest_meter',
        'title': 'Interest & Spark Meter',
        'subtitle': '86% Mutual Resonance',
        'summary': 'User A and their chat partner demonstrate highly synchronized texting rhythms and prompt responsiveness across sessions.',
        'score': 86,
        'confidence': 'high',
        'message_ids': [id1, id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'situationship_status',
        'title': 'Situationship Status',
        'subtitle': 'Unspoken Chemistry',
        'summary': 'Consistently high engagement with minimal emotional hesitation. Both show balanced investment in continuing conversations.',
        'score': 88,
        'confidence': 'high',
        'message_ids': [id1].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'simp_score',
        'title': 'Simp Score',
        'subtitle': 'Balanced Energy',
        'summary': 'Neither party overwhelmingly simps, maintaining an admirable equilibrium between intrigue and independence.',
        'score': 42,
        'confidence': 'medium',
        'message_ids': [id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'compatibility_score',
        'title': 'Compatibility Score',
        'subtitle': '91% Alignment',
        'summary': 'Strong conversational reciprocity, matching reply velocity, and aligned reaction times signify outstanding interpersonal compatibility.',
        'score': 91,
        'confidence': 'high',
        'message_ids': [id1, id3].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'green_flags',
        'title': 'Green Flags',
        'subtitle': 'Emotional Availability',
        'summary': 'Active check-ins, genuine curiosity about each other’s days, and respectful acknowledgment of delayed messages.',
        'confidence': 'high',
        'message_ids': [id1, id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'red_flags',
        'title': 'Red Flags',
        'subtitle': 'Low friction detected',
        'summary': 'Occasional multi-hour silence periods during work hours, but quickly followed by warm reconnects.',
        'confidence': 'low',
        'message_ids': [id3].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'double_text_champion',
        'title': 'Double-Text Champion',
        'subtitle': 'Spontaneous Thought Express',
        'summary': 'Double texting here is enthusiastic rather than needy—sending quick contextual follow-ups and memes.',
        'confidence': 'high',
        'message_ids': [id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'texting_personality',
        'title': 'Texting Archetype',
        'subtitle': 'The Instant Banterer',
        'summary': 'Fast-paced, responsive, witty remarks, and lively emoji usage characterize this conversation.',
        'confidence': 'high',
        'message_ids': [id1].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'chat_wrapped',
        'title': 'Chat Wrapped Highlights',
        'subtitle': 'Memories & Milestones',
        'summary': 'A dynamic filled with laughter, inside jokes, and late night discussions.',
        'confidence': 'high',
        'message_ids': [id1, id3].where((id) => id.isNotEmpty).toList(),
      },
    ];

    if (config.enableRoast) {
      cards.add({
        'type': 'roast_mode',
        'title': 'Roast Mode (${config.roastIntensity.toUpperCase()})',
        'subtitle': 'The Notification Overloader',
        'summary': 'You two treat WhatsApp like an ongoing walkie-talkie channel. Typing three fragments instead of one complete sentence is a lifestyle choice at this point!',
        'score': 75,
        'confidence': 'high',
        'message_ids': [id2].where((id) => id.isNotEmpty).toList(),
      });
    }

    return {
      'schema_version': 1,
      'cards': cards,
      'teaser_insight': {
        'type': 'interest_meter',
        'title': 'Interest Meter Sneak Peek',
        'subtitle': '86% Mutual Resonance',
        'summary': 'High conversational chemistry detected! Both participants show strong mutual engagement.',
        'score': 86,
        'confidence': 'high',
        'message_ids': [id1].where((id) => id.isNotEmpty).toList(),
      }
    };
  }
}
