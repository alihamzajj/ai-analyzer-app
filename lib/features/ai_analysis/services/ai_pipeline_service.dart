import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/backend_config.dart';
import '../../../core/utils/anonymous_id.dart';
import '../../../core/utils/roman_urdu.dart';
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

  /// Uses the live Supabase backend when configured, otherwise the offline demo.
  factory AiPipelineService.fromConfig() {
    SupabaseClient? client;
    if (BackendConfig.isConfigured) {
      try {
        client = Supabase.instance.client;
      } catch (_) {
        client = null; // Supabase failed to initialise at startup
      }
    }
    return AiPipelineService(supabaseClient: client);
  }

  /// True when reports come from real AI rather than the offline demo.
  bool get isLive => supabaseClient != null || (customBackendUrl?.isNotEmpty ?? false);

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
        // Real AI: the Edge Function holds the Gemini key server-side.
        final res = await supabaseClient!.functions.invoke(
          AppConstants.functionAnalyseChat,
          body: requestBody,
          headers: {'x-anonymous-user-id': await AnonymousId.get()},
        );
        responseData = res.data is String ? jsonDecode(res.data) : Map<String, dynamic>.from(res.data as Map);
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
    } on FunctionException catch (e) {
      throw AiServiceException(
        _friendlyBackendError(e.status),
        code: 'BACKEND_STATUS_${e.status}',
        details: e.details,
        isRetryable: e.status != 429,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AiServiceException('Failed to generate report: $e', details: e);
    }
  }

  static String _friendlyBackendError(int status) {
    if (status == 429) {
      return 'AI is busy or you reached the fair-use limit. Please try again in a little while.';
    }
    if (status >= 500) {
      return 'Our AI server had a hiccup. Please try again in a minute.';
    }
    return 'Could not reach the AI service (error $status). Check your internet and try again.';
  }

  /// Generates a valid local fallback report for instant offline capability or development
  static Map<String, dynamic> _generateLocalFallbackResponse({
    required ChatSetupConfig config,
    required DigestPayload digestPayload,
    required ChatStatistics statistics,
  }) {
    // Demo text follows the chosen output language (English or Roman Urdu).
    final romanUrdu = config.outputLanguage == RomanUrdu.languageCode;
    String t(String en, String ur) => romanUrdu ? ur : en;

    final sampleIds = digestPayload.compactMessages.take(4).map((m) => m['id'] as String).toList();
    final id1 = sampleIds.isNotEmpty ? sampleIds[0] : '';
    final id2 = sampleIds.length > 1 ? sampleIds[1] : id1;
    final id3 = sampleIds.length > 2 ? sampleIds[2] : id1;

    final cards = [
      {
        'type': 'interest_meter',
        'title': t('Interest & Spark Meter', 'Interest Meter'),
        'subtitle': t('86% Mutual Resonance', 'Dono taraf se 86% vibe'),
        'summary': t('User A and their chat partner demonstrate highly synchronized texting rhythms and prompt responsiveness across sessions.', 'Dono ka texting ka rhythm bilkul match karta hai, aur reply bhi jaldi aate hain. Yeh chat clearly dono ke liye important hai.'),
        'score': 86,
        'confidence': 'high',
        'message_ids': [id1, id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'situationship_status',
        'title': t('Situationship Status', 'Situationship Status'),
        'subtitle': t('Unspoken Chemistry', 'Kuch toh hai jo bola nahi gaya'),
        'summary': t('Consistently high engagement with minimal emotional hesitation. Both show balanced investment in continuing conversations.', 'Baat cheet mein dono barabar interest dikhate hain. Koi jhijhak nahi, aur dono chahte hain ke baat chalti rahe.'),
        'score': 88,
        'confidence': 'high',
        'message_ids': [id1].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'simp_score',
        'title': t('Simp Score', 'Simp Score'),
        'subtitle': t('Balanced Energy', 'Energy barabar hai'),
        'summary': t('Neither party overwhelmingly simps, maintaining an admirable equilibrium between intrigue and independence.', 'Koi bhi hadd se zyada simp nahi kar raha. Interest bhi hai aur apni izzat bhi, perfect balance.'),
        'score': 42,
        'confidence': 'medium',
        'message_ids': [id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'compatibility_score',
        'title': t('Compatibility Score', 'Compatibility Score'),
        'subtitle': t('91% Alignment', '91% match'),
        'summary': t('Strong conversational reciprocity, matching reply velocity, and aligned reaction times signify outstanding interpersonal compatibility.', 'Jitna ek deta hai utna doosra lautata hai. Reply speed aur mood dono match karte hain, solid jodi hai.'),
        'score': 91,
        'confidence': 'high',
        'message_ids': [id1, id3].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'green_flags',
        'title': t('Green Flags', 'Green Flags'),
        'subtitle': t('Emotional Availability', 'Khayal rakhne wale'),
        'summary': t('Active check-ins, genuine curiosity about each other’s days, and respectful acknowledgment of delayed messages.', '"Pohanch k batana", "khana khaya?" jaise check-ins, ek doosre ke din mein sach mein interest, aur late reply pe bhi izzat se baat.'),
        'confidence': 'high',
        'message_ids': [id1, id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'red_flags',
        'title': t('Red Flags', 'Red Flags'),
        'subtitle': t('Low friction detected', 'Zyada masla nahi'),
        'summary': t('Occasional multi-hour silence periods during work hours, but quickly followed by warm reconnects.', 'Kaam ke time kabhi kabhi ghanton ki khamoshi, lekin phir jaldi hi pyar se baat shuru ho jati hai.'),
        'confidence': 'low',
        'message_ids': [id3].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'double_text_champion',
        'title': t('Double-Text Champion', 'Double-Text Champion'),
        'subtitle': t('Spontaneous Thought Express', 'Dimagh mein aya, bhej diya'),
        'summary': t('Double texting here is enthusiastic rather than needy—sending quick contextual follow-ups and memes.', 'Yahan double text desperation nahi, excitement hai. Foran follow-up aur memes bhejna inki aadat hai.'),
        'confidence': 'high',
        'message_ids': [id2].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'texting_personality',
        'title': t('Texting Archetype', 'Texting Personality'),
        'subtitle': t('The Instant Banterer', 'Hazir-jawab'),
        'summary': t('Fast-paced, responsive, witty remarks, and lively emoji usage characterize this conversation.', 'Tez replies, mazedaar jumlay aur emojis ki barsaat. Is chat mein boredom ka koi chance nahi.'),
        'confidence': 'high',
        'message_ids': [id1].where((id) => id.isNotEmpty).toList(),
      },
      {
        'type': 'chat_wrapped',
        'title': t('Chat Wrapped Highlights', 'Chat Wrapped'),
        'subtitle': t('Memories & Milestones', 'Yaadein aur lamhe'),
        'summary': t('A dynamic filled with laughter, inside jokes, and late night discussions.', 'Hansi, inside jokes aur raat der tak lambi baatein. Yeh chat dosti ki diary hai.'),
        'confidence': 'high',
        'message_ids': [id1, id3].where((id) => id.isNotEmpty).toList(),
      },
    ];

    if (config.enableRoast) {
      cards.add({
        'type': 'roast_mode',
        'title': 'Roast Mode (${config.roastIntensity.toUpperCase()})',
        'subtitle': t('The Notification Overloader', 'Notification ka toofan'),
        'summary': t('You two treat WhatsApp like an ongoing walkie-talkie channel. Typing three fragments instead of one complete sentence is a lifestyle choice at this point!', 'Aap dono WhatsApp ko walkie-talkie samajhte ho. Ek line ki jagah teen tukde bhejna ab lifestyle ban chuka hai 😭'),
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
        'title': t('Interest Meter Sneak Peek', 'Interest Meter ki jhalak'),
        'subtitle': t('86% Mutual Resonance', 'Dono taraf se 86% vibe'),
        'summary': t('High conversational chemistry detected! Both participants show strong mutual engagement.', 'Zabardast chemistry! Dono taraf se baat karne ka shauq saaf nazar aata hai.'),
        'score': 86,
        'confidence': 'high',
        'message_ids': [id1].where((id) => id.isNotEmpty).toList(),
      }
    };
  }
}
