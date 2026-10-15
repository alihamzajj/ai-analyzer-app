import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../ai_analysis/models/report_card.dart';
import '../../chat_parser/models/parsed_message.dart';

class ReceiptDetailsSheet extends StatelessWidget {
  final ReportCard card;
  final List<ParsedMessage> sourceMessages;

  const ReceiptDetailsSheet({
    super.key,
    required this.card,
    required this.sourceMessages,
  });

  static void show(BuildContext context, ReportCard card, List<ParsedMessage> sourceMessages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptDetailsSheet(card: card, sourceMessages: sourceMessages),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lookup matching messages
    final Map<String, ParsedMessage> lookup = {
      for (final m in sourceMessages) m.id: m,
    };

    final matchedMessages = card.messageIds
        .map((id) => lookup[id])
        .whereType<ParsedMessage>()
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Verifiable Receipts', style: AppTypography.titleMedium),
                      Text(
                        'Direct evidence for: ${card.title}',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Message receipts list
          Flexible(
            child: matchedMessages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_outlined, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Holistic Conversation Metric',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This card reflects aggregate response times and interaction volume across the entire conversation history rather than isolated messages.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    shrinkWrap: true,
                    itemCount: matchedMessages.length,
                    itemBuilder: (context, index) {
                      final msg = matchedMessages[index];
                      final timeStr = msg.timestamp != null
                          ? '${msg.timestamp!.month}/${msg.timestamp!.day} • ${msg.timestamp!.hour.toString().padLeft(2, '0')}:${msg.timestamp!.minute.toString().padLeft(2, '0')}'
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sender and timestamp
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                                      child: Text(
                                        msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 10, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      msg.senderName,
                                      style: AppTypography.labelLarge,
                                    ),
                                  ],
                                ),
                                Text(
                                  timeStr,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Exact Message Text
                            Text(
                              msg.content,
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 10),

                            // Verifiable ID Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ID: ${msg.id}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
