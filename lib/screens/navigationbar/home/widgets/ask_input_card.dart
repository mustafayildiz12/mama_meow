import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/navigationbar/home/voice_recorder_controller.dart';

/// Soru kutusu: metin, görsel ekleme, sesli soru ve "Ask" düğmesi.
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 4,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                hintText: "Ask me anything about babies and moms! 😸🐾",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.pink200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.pink400,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: voice,
              builder: (context, _) => _buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final isRecording = voice.isRecording;
    final isTranscribing = voice.isTranscribing;
    final image = imageBytes;

    return Row(
      children: [
        IconButton(
          tooltip: 'Add a photo',
          icon: const Icon(Icons.camera_alt, color: Colors.teal),
          onPressed: isLoading ? null : onPickImage,
        ),
        IconButton.filledTonal(
          tooltip: isRecording ? 'Stop recording' : 'Ask with your voice',
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              isRecording ? Colors.red.shade400 : Colors.deepPurple.shade100,
            ),
          ),
          icon: Icon(
            isRecording ? Icons.stop : Icons.mic,
            color: isRecording ? Colors.white : Colors.deepPurple,
          ),
          onPressed: (isLoading || isTranscribing) ? null : onMicPressed,
        ),

        if (isRecording)
          Expanded(child: _RecordingIndicator(voice: voice))
        else if (isTranscribing)
          const Expanded(child: _TranscribingIndicator())
        else
          const Spacer(),

        if (image != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
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
                    child: InkWell(
                      onTap: isLoading ? null : onRemoveImage,
                      child: const Icon(Icons.cancel, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!isRecording)
          ElevatedButton.icon(
            onPressed: (isLoading || isTranscribing) ? null : onAsk,
            icon: const Icon(Icons.send),
            label: const Text("Ask"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pink400,
              disabledBackgroundColor: AppColors.pink400.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: voice.amplitude, // 0..1
              minHeight: 8,
            ),
          ),
        ),
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
        SizedBox(width: 8),
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            "Transcribing…",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.black54),
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
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
