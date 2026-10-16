import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/navigationbar/home/voice_recorder_controller.dart';

/// Soru kutusu (ekranın altındaki giriş çubuğu): metin, görsel ekleme,
/// sesli soru ve gönder düğmesi.
class AskInputCard extends StatelessWidget {
  const AskInputCard({
    super.key,
    required this.controller,
    required this.voice,
    required this.isLoading,
    required this.imageBytes,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onMicPressed,
    required this.onAsk,
  });

  final TextEditingController controller;
  final VoiceRecorderController voice;
  final bool isLoading;
  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onMicPressed;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final pillRadius = BorderRadius.circular(24);

    // Metin kutusu ses durumundan bağımsızdır; her genlik güncellemesinde
    // yeniden kurulmasın diye ListenableBuilder'a child olarak verilir.
    final textField = TextField(
      controller: controller,
      minLines: 1,
      maxLines: 4,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: const TextStyle(
        fontSize: 15,
        height: 22 / 15,
        color: AppColors.deepCharcoal,
      ),
      decoration: InputDecoration(
        hintText: "Ask me anything about babies and moms!",
        hintMaxLines: 1,
        hintStyle: const TextStyle(
          fontSize: 15,
          height: 22 / 15,
          color: AppColors.charcoalSoft,
          overflow: TextOverflow.ellipsis,
        ),
        isDense: true,
        filled: true,
        fillColor: AppColors.cottonWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: const BorderSide(color: AppColors.activeBerry, width: 2),
        ),
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cottonWhite,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
        child: ListenableBuilder(
          listenable: voice,
          child: textField,
          builder: (context, field) => _buildBar(field!),
        ),
      ),
    );
  }

  Widget _buildBar(Widget field) {
    final isRecording = voice.isRecording;
    final isTranscribing = voice.isTranscribing;
    final image = imageBytes;
    final showStatus = image != null || isRecording || isTranscribing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ------ Durum satırı: görsel önizleme + kayıt / yazıya çevirme ------
        if (showStatus)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 0, 10),
            child: Row(
              children: [
                if (image != null) ...[
                  _ImagePreview(
                    image: image,
                    onRemove: isLoading ? null : onRemoveImage,
                  ),
                  const SizedBox(width: 12),
                ],
                if (isRecording)
                  Expanded(child: _RecordingIndicator(voice: voice))
                else if (isTranscribing)
                  const Expanded(child: _TranscribingIndicator())
                else
                  const Spacer(),
              ],
            ),
          ),

        // ------ Giriş satırı ------
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Add a photo',
              icon: const Icon(Icons.photo_camera_outlined),
              color: AppColors.deepCharcoal,
              onPressed: isLoading ? null : onPickImage,
            ),
            IconButton(
              tooltip: isRecording ? 'Stop recording' : 'Ask with your voice',
              style: isRecording
                  ? IconButton.styleFrom(
                      backgroundColor: AppColors.activeBerry,
                      foregroundColor: AppColors.cottonWhite,
                    )
                  : null,
              icon: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
              ),
              color: isRecording
                  ? AppColors.cottonWhite
                  : AppColors.deepCharcoal,
              onPressed: (isLoading || isTranscribing) ? null : onMicPressed,
            ),
            const SizedBox(width: 4),
            Expanded(child: field),
            if (!isRecording) ...[
              const SizedBox(width: 8),
              _SendButton(
                onPressed: (isLoading || isTranscribing) ? null : onAsk,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// 48 px yuvarlak berry gönder düğmesi.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const CircleBorder(),
        shadows: enabled ? AppColors.berryGlow : null,
      ),
      child: IconButton(
        tooltip: 'Ask',
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_upward),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          minimumSize: const Size(48, 48),
          backgroundColor: AppColors.activeBerry,
          foregroundColor: AppColors.cottonWhite,
          disabledBackgroundColor: AppColors.warmPink,
          disabledForegroundColor: AppColors.cottonWhite,
        ),
      ),
    );
  }
}

/// Eklenen görselin küçük önizlemesi ve kaldırma düğmesi.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, required this.onRemove});

  final Uint8List image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
            image: DecorationImage(
              image: MemoryImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Semantics(
            button: true,
            label: 'Remove photo',
            child: Material(
              color: AppColors.pinkTint,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.cottonWhite, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.deepCharcoal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kayıt göstergesi: yanıp sönen nokta + süre + seviye çubuğu.
class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator({required this.voice});

  final VoiceRecorderController voice;

  static String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BlinkingDot(),
        const SizedBox(width: 8),
        Text(
          _format(voice.elapsed),
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w700,
            color: AppColors.deepCharcoal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: voice.amplitude, // 0..1
              minHeight: 8,
              color: AppColors.activeBerry,
              backgroundColor: AppColors.pinkTint,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _TranscribingIndicator extends StatelessWidget {
  const _TranscribingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.activeBerry,
          ),
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            "Transcribing…",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.charcoalSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.activeBerry,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
