import 'package:flutter/material.dart';
import 'package:mama_meow/models/ai_models/mia_answer_model.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/url_utils.dart';

/// Mia'nın cevabını gösteren kart (güncel cevap ve geçmiş sorular için).
///
/// [onShare] verilirse "Share" düğmesi; [suggestions] doluysa altında
/// tıklanabilir öneriler gösterilir.
class MiaAnswerCard extends StatelessWidget {
  const MiaAnswerCard({
    super.key,
    required this.answer,
    this.suggestions = const [],
    this.onSuggestionTap,
    this.onShare,
  });

  final MiaAnswer answer;
  final List<String> suggestions;

  /// null ise öneriler pasif görünür.
  final ValueChanged<String>? onSuggestionTap;

  /// Paylaşım popover'ının (iPad) konumu için düğmenin context'i verilir.
  final void Function(BuildContext anchorContext)? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final share = onShare;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------ Hızlı cevap ------
            Text(
              answer.quick,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
            ),
            if (share != null) ...[
              const SizedBox(height: 4),
              // Cevabı paylaş (büyüme kancası: ebeveynler tavsiyeyi yayar).
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (buttonContext) => TextButton.icon(
                    onPressed: () => share(buttonContext),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text("Share"),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ] else
              const SizedBox(height: 10),

            // ------ Detaylı bilgi ------
            if (answer.detailed.trim().isNotEmpty) ...[
              Text(
                "Detailed Info",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(answer.detailed.replaceAll(r'\n', '\n')),
              const SizedBox(height: 12),
            ],

            // ------ Aksiyonlar ------
            if (answer.actions.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in answer.actions)
                    Chip(
                      label: Row(
                        children: [
                          Expanded(
                            child: Text(
                              action,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ------ Takip sorusu ------
            if (answer.followUp.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.question_answer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        answer.followUp,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ------ Kaynaklar ------
            if (answer.sources.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.link, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "Sources",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final source in answer.sources) _SourceTile(item: source),
              const SizedBox(height: 8),
            ],

            // ------ Uyarı + son güncelleme ------
            Text(
              answer.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            if (answer.lastUpdated.isNotEmpty)
              Text(
                "Last updated: ${answer.lastUpdated}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                ),
              ),
            const SizedBox(height: 12),

            // ------ Öneriler ------
            if (suggestions.isNotEmpty)
              _Suggestions(suggestions: suggestions, onTap: onSuggestionTap),
          ],
        ),
      ),
    );
  }
}

/// Cevap beklenirken gösterilen kart.
class MiaThinkingCard extends StatelessWidget {
  const MiaThinkingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                "Mia is thinking…",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Maybe these also help:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final suggestion in suggestions)
          InkWell(
            onTap: tap == null ? null : () => tap(suggestion),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text("👉 $suggestion"),
            ),
          ),
      ],
    );
  }
}

// ---- Kaynak satırı ----
class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.item});

  final MiaSource item;

  Future<void> _open() async {
    final opened = await UrlUtils.openExternal(item.url);
    if (!opened) customSnackBar.warning("Couldn't open this link");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLink = UrlUtils.isWebUrl(item.url);
    final subtitleBits = <String>[
      if (item.publisher.isNotEmpty) item.publisher,
      if (item.year != null) "${item.year}",
    ];
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: isLink ? TextDecoration.underline : null,
        ),
      ),
      subtitle: subtitleBits.isEmpty ? null : Text(subtitleBits.join(" • ")),
      trailing: isLink ? const Icon(Icons.open_in_new, size: 16) : null,
      onTap: isLink ? _open : null,
    );
  }
}
