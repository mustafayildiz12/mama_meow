import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/ai_models/mia_answer_model.dart';
import 'package:mama_meow/service/gpt_service/common/ai_common.dart';
import 'package:mama_meow/service/gpt_service/openai_proxy_service.dart';

/// Ask Meow sohbeti, öneriler ve ses transkripsiyonu.
///
/// Tüm OpenAI çağrıları [openAiProxyService] (Cloud Functions proxy)
/// üzerinden gider; anahtar/kota sunucu tarafında yönetilir.
class GptService {
  static const Set<String> _supportedImageMimes = {
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  };

  // =======================
  // 1) askMia
  // =======================
  /// Soru sorar; opsiyonel görsel eklenebilir.
  ///
  /// Görsel formatı baytlardan tespit edilir; desteklenmeyen formatlar PNG'ye
  /// çevrilir. Tespit/çevirme başarısızsa [imageMimeType] (desteklenen bir
  /// tipse) kullanılır.
  ///
  /// Başarısızlıkta null döner; sebep loglanır (proxy hataları proxy
  /// tarafından Crashlytics'e kaydedilir).
  Future<MiaAnswer?> askMia(
    String question, {
    Uint8List? imageBytes,
    String imageMimeType = 'image/png', // 'image/jpeg' vb.
    int maxTokens = 600,
    double temperature = 0.7,
  }) async {
    ({Uint8List bytes, String mime})? image;
    if (imageBytes != null) {
      try {
        image = _ensureSupportedImage(imageBytes, hintMime: imageMimeType);
      } catch (e, st) {
        reportAiNonFatal(e, st, reason: 'askMia: image preparation failed');
        return null;
      }
    }

    // Chat Completions şemasına uygun messages
    final userContent = <Map<String, dynamic>>[
      {'type': 'text', 'text': question},
      if (image != null)
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:${image.mime};base64,${base64Encode(image.bytes)}',
          },
        },
    ];

    final String raw;
    try {
      raw = await openAiProxyService.chat(
        messages: [
          {'role': 'system', 'content': _askMiaSystemPrompt()},
          {'role': 'user', 'content': userContent},
        ],
        model: askMiaModel,
        maxTokens: maxTokens,
        temperature: temperature,
        responseFormat: kJsonObjectResponseFormat,
      );
    } catch (e, st) {
      // Proxy callable hatasını zaten Crashlytics'e kaydetti.
      developer.log(
        'askMia request failed',
        name: 'GptService',
        error: e,
        stackTrace: st,
      );
      return null;
    }

    final map = decodeJsonObject(raw, tag: 'askMia');
    if (map == null) return null;
    try {
      return MiaAnswer.fromMap(map);
    } catch (e, st) {
      reportAiNonFatal(e, st, reason: 'askMia: answer parse failed');
      return null;
    }
  }

  /// Uzak (appInfo) prompt boşsa yerel varsayılan kullanılır. JSON modu için
  /// prompt'ta "JSON" geçmesi zorunlu olduğundan gerekirse eklenir.
  String _askMiaSystemPrompt() {
    var base = systemPrompt.trim().isEmpty ? emptySystemPrompt : systemPrompt;
    if (!base.toLowerCase().contains('json')) {
      base = '$base\n\nRespond with a single JSON object only.';
    }
    return '$base${babyPersonalization(instruction: "Please personalize your response accordingly and use the baby's name when appropriate.")}';
  }

  // =======================
  // 2) getSuggestions
  // =======================
  /// Kullanıcının sorusuna göre 3 öneri döndürür (satır bazlı düz metin).
  ///
  /// [language] artık kullanılmıyor (geriye dönük uyumluluk için duruyor):
  /// model, sorunun yazıldığı dilde cevap verir.
  Future<List<String>> getSuggestions({
    required String question,
    String? language,
    int maxTokens = 200,
    double temperature = 0.8,
  }) async {
    try {
      final prompt = suggestionPrompt.trim().isEmpty
          ? emptySuggestionPrompt
          : suggestionPrompt;
      final content = await openAiProxyService.chat(
        messages: [
          {'role': 'system', 'content': prompt},
          {
            'role': 'user',
            'content':
                'User\'s question: "$question"\n\n'
                'Provide 3 related suggestions in the same language as the question:',
          },
        ],
        model: askMiaModel,
        maxTokens: maxTokens,
        temperature: temperature,
      );

      if (content.isEmpty) return [];

      // Satırlara böl; olası madde işareti/numaraları temizle.
      final bullet = RegExp(r'^\s*(?:[-*•]|\d+[.)])\s*');
      return content
          .split('\n')
          .map((e) => e.replaceFirst(bullet, '').trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    } catch (e, st) {
      developer.log(
        'getSuggestions failed',
        name: 'GptService',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // =======================
  // 3) transcribeAudio (Whisper)
  // =======================
  /// Ses dosyasını (bytes) çözümler. Başarısızsa veya metin boşsa null döner
  /// (hata, proxy tarafından Crashlytics'e non-fatal olarak kaydedilir).
  Future<String?> transcribeAudio(
    Uint8List audioBytes, {

    /// Dosya adı ve MIME, mümkünse gerçek içerikle uyumlu olsun:
    /// Örn: "recording.m4a" + "audio/mp4"  (m4a genelde AAC içerir)
    ///      "clip.webm"     + "audio/webm"
    ///      "voice.mp3"     + "audio/mpeg"
    String filename = 'audio.webm',
    String mimeType = 'audio/webm',

    /// Modeller: "gpt-4o-mini-transcribe", "gpt-4o-transcribe", "whisper-1"
    String model = 'gpt-4o-mini-transcribe',

    /// İsteğe bağlılar
    String? language, // "tr", "en", "de" vb. (Whisper ile uyumlu)
    String? prompt, // Modeli yönlendirmek için ipucu
    double? temperature, // 0.0 - 1.0, varsayılan genelde 0
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      // Ses baytları proxy'ye base64 olarak gider; multipart sunucuda kurulur.
      final text = await openAiProxyService.transcribe(
        audioBytes: audioBytes,
        filename: filename,
        mimeType: mimeType,
        model: model,
        language: language,
        prompt: prompt,
        temperature: temperature,
        timeout: timeout,
      );
      final trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (e, st) {
      developer.log(
        'transcribeAudio failed',
        name: 'GptService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Bayttan basit MIME tespiti; tanınmazsa null.
  String? _detectMime(Uint8List bytes) {
    if (bytes.length > 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length > 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }
    if (bytes.length > 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    if (bytes.length > 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp'; // BMP (desteklenmiyor → PNG'ye çevrilir)
    }
    return null;
  }

  /// Desteklenen formatı olduğu gibi döner; diğerlerini PNG'ye çevirir.
  /// Çevrilemezse ve [hintMime] desteklenen bir tipse onu kullanır.
  ({Uint8List bytes, String mime}) _ensureSupportedImage(
    Uint8List bytes, {
    String? hintMime,
  }) {
    final detected = _detectMime(bytes);
    if (detected != null && _supportedImageMimes.contains(detected)) {
      return (bytes: bytes, mime: detected);
    }

    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      return (
        bytes: Uint8List.fromList(img.encodePng(decoded)),
        mime: 'image/png',
      );
    }

    var hint = hintMime?.trim().toLowerCase();
    if (hint == 'image/jpg') hint = 'image/jpeg';
    if (hint != null && _supportedImageMimes.contains(hint)) {
      return (bytes: bytes, mime: hint);
    }
    throw FormatException('Unsupported image format (hint: $hintMime)');
  }
}
