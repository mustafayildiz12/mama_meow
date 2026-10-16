import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/ai_models/mia_answer_model.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/url_utils.dart';

const _bodyStyle = TextStyle(
  fontSize: 16,
  height: 24 / 16,
  color: AppColors.deepCharcoal,
);

const _secondaryBodyStyle = TextStyle(
  fontSize: 15,
  height: 22 / 15,
  color: AppColors.deepCharcoal,
);

const _captionStyle = TextStyle(
  fontSize: 12,
  height: 16 / 12,
  fontWeight: FontWeight.w600,
  color: AppColors.charcoalSoft,
);

/// Kullanıcının sorduğu soru (sağa yaslı pembe balon).
class AskedQuestionBubble extends StatelessWidget {
  const AskedQuestionBubble({super.key, required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.pinkTint,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(question, style: _bodyStyle),
        ),
      ),
    );
  }
}

/// Mia'nın cevabını gösteren kart (güncel cevap ve geçmiş sorular için).
///
/// [onShare] verilirse "Share" düğmesi; [suggestions] doluysa kartın altında
/// tıklanabilir öneriler gösterilir. [framed] false ise (geçmiş listesinde
/// zaten bir kartın içinde) beyaz kart çerçevesi çizilmez.
class MiaAnswerCard extends StatelessWidget {
  const MiaAnswerCard({
    super.key,
    required this.answer,
    this.suggestions = const [],
    this.onSuggestionTap,
    this.onShare,
    this.framed = true,
  });

  final MiaAnswer answer;
  final List<String> suggestions;

  /// null ise öneriler pasif görünür.
  final ValueChanged<String>? onSuggestionTap;

  /// Paylaşım popover'ının (iPad) konumu için düğmenin context'i verilir.
  final void Function(BuildContext anchorContext)? onShare;

  final bool framed;

  @override
  Widget build(BuildContext context) {
    final share = onShare;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MeowLabel(),
        const SizedBox(height: 12),

        // ------ Hızlı cevap ------
        Text(answer.quick, style: _bodyStyle),

        // ------ Aksiyonlar (ipuçları) ------
        if (answer.actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TipBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < answer.actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _Bullet(text: answer.actions[i]),
                ],
              ],
            ),
          ),
        ],

        // ------ Takip sorusu ------
        if (answer.followUp.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _TipBlock(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.question_answer_outlined,
                    size: 18,
                    color: AppColors.activeBerry,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    answer.followUp,
                    style: _secondaryBodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ------ Detaylı bilgi (açılır satır) ------
        if (answer.detailed.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: AppColors.deepCharcoal,
            collapsedIconColor: AppColors.deepCharcoal,
            title: const Text(
              "Detailed Info",
              style: TextStyle(
                fontSize: 15,
                height: 22 / 15,
                fontWeight: FontWeight.w800,
                color: AppColors.deepCharcoal,
              ),
            ),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            children: [
              Text(
                answer.detailed.replaceAll(r'\n', '\n'),
                style: _secondaryBodyStyle,
              ),
            ],
          ),
          const Divider(height: 1),
        ],

        // ------ Kaynaklar ------
        if (answer.sources.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            "Sources",
            style: _captionStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final source in answer.sources) _SourceChip(item: source),
            ],
          ),
        ],

        // ------ Uyarı + son güncelleme ------
        if (answer.disclaimer.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(answer.disclaimer, style: _captionStyle),
        ],
        if (answer.lastUpdated.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text("Last updated: ${answer.lastUpdated}", style: _captionStyle),
        ],

        // ------ Paylaş ------
        if (share != null) ...[
          const SizedBox(height: 4),
          // Cevabı paylaş (büyüme kancası: ebeveynler tavsiyeyi yayar).
          Align(
            alignment: Alignment.centerRight,
            child: Builder(
              builder: (buttonContext) => TextButton.icon(
                onPressed: () => share(buttonContext),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text("Share"),
              ),
            ),
          ),
        ],
      ],
    );

    if (!framed) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: EdgeInsets.fromLTRB(20, 16, 20, share != null ? 8 : 20),
          child: content,
        ),

        // ------ Öneriler ------
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Suggestions(suggestions: suggestions, onTap: onSuggestionTap),
        ],
      ],
    );
  }
}

/// Cevap beklenirken gösterilen kart.
class MiaThinkingCard extends StatelessWidget {
  const MiaThinkingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          _MeowAvatar(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Mia is thinking…",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoalSoft,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.activeBerry,
            ),
          ),
        ],
      ),
    );
  }
}

/// Şeftali daire içinde küçük pati avatarı.
class _MeowAvatar extends StatelessWidget {
  const _MeowAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.peachTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline),
      ),
      child: const Icon(Icons.pets, size: 17, color: AppColors.berryInk),
    );
  }
}

/// Kart başlığı: avatar + "Meow" + parıltı ikonu.
class _MeowLabel extends StatelessWidget {
  const _MeowLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _MeowAvatar(),
        SizedBox(width: 10),
        Text(
          "Meow",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.berryInk,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.auto_awesome, size: 16, color: AppColors.activeBerry),
      ],
    );
  }
}

/// Şeftali zeminli ipucu bloğu.
class _TipBlock extends StatelessWidget {
  const _TipBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.peachTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Berry noktalı madde satırı.
class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppColors.activeBerry,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: _secondaryBodyStyle)),
      ],
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
        Text(
          "Maybe these also help:",
          style: _captionStyle.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in suggestions)
              Material(
                color: AppColors.pinkTint,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: tap == null ? null : () => tap(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: AppColors.activeBerry,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepCharcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---- Kaynak hapı ----
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.item});

  final MiaSource item;

  Future<void> _open() async {
    final opened = await UrlUtils.openExternal(item.url);
    if (!opened) customSnackBar.warning("Couldn't open this link");
  }

  @override
  Widget build(BuildContext context) {
    final isLink = UrlUtils.isWebUrl(item.url);
    final subtitleBits = <String>[
      if (item.publisher.isNotEmpty) item.publisher,
      if (item.year != null) "${item.year}",
    ];
    final labelColor = isLink ? AppColors.berryInk : AppColors.deepCharcoal;

    return Material(
      color: AppColors.peachTint,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLink ? _open : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: item.title,
                    style: TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                    children: [
                      if (subtitleBits.isNotEmpty)
                        TextSpan(
                          text: "  ${subtitleBits.join(" • ")}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoalSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isLink) ...[
                const SizedBox(width: 6),
                Icon(Icons.open_in_new, size: 14, color: labelColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
