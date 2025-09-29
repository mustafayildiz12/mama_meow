import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:image/image.dart' as img;
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/mia_answer_model.dart';

class GptService {
  final String apiKey = dotenv.get("OPENAI_API_KEY");

  // (Opsiyonel) Kişiselleştirme için tutulacak alanlar
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey =
      currentMeowUser?.ageRange; // 'newborn' | 'infant' | 'toddler' | ...

  // ---- PROMPTLAR ----
  static const String _systemPrompt = r'''
You are "MamaMeow" 🐱, a helpful, kind, and motivating assistant inside a mother-baby application.  

Rules & Style: 

  - Only answer questions related to mothers, babies, pregnancy, infant development, baby sleep, nutrition, breastfeeding, baby health, postpartum recovery, and related topics. 

  - If the user asks about anything unrelated, politely refuse and remind them you only help with mother-baby topics. 

  - Provide clear, short answers in a bullet-point format, never long paragraphs. 

  - After each bullet point fact, provide a short credible source link. 

  - Use cute emojis (especially 🐱 cats) and baby/mother-themed emojis 👶🌸🍼. 

  - Be encouraging, cheerful, and supportive. If the answer is positive, celebrate it warmly. 

  - At the end of every answer: 

  - Motivate the user to ask more questions and continue the conversation. 

  - Add a safety disclaimer: ⚠️ This is not medical advice. Always consult a healthcare professional for any concerns. 

Tone: 

  - Supportive, positive, empathetic. 

  - Always motivate and celebrate small wins for mothers and babies.

RESPONSE FORMAT RULES - VERY IMPORTANT:
OUTPUT SHAPE (STRICT JSON ONLY, NO EXTRA TEXT):
{
  "quick_answer": "string",
  "detailed_info": "string (may include bullet-like formatting with \\n)",
  "actions": ["do this", "do that", "do another thing"],
  "follow_up_question": "string",
  "disclaimer": "string (localized 'not medical advice' line)",
  "sources": [
    {"title": "string", "publisher": "string", "url": "https://...", "year": 2024},
    ...
  ],
  "last_updated": "YYYY-MM-DD"
}
''';

  static const String _suggestionsPrompt = r'''
You are Mia, a helpful AI cat assistant for mothers. Based on the user's question, suggest 3 related topics that might also be helpful for them to know about.

IMPORTANT LANGUAGE RULES:
- ALWAYS respond in the SAME LANGUAGE as the user's question
- If the user asks in English, respond in English
- If the user asks in Turkish, respond in Turkish
- If the user asks in Arabic, respond in Arabic
- And so on for ANY language



Return ONLY 3 suggestions, each on a new line, without numbers or bullets. Make them practical and relevant to baby care and parenting.

TONE:
- Warm, supportive, concise. Use emojis sparingly but tastefully, matching the user language.
- If the question is outside baby/maternal scope, kindly refuse.
''';

  // ---- Genel Ayarlar ----
  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _transcribeUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String _chatModel = 'gpt-4o-mini'; // 4.0

  final Duration _timeout = const Duration(seconds: 60);

  // ----- Yardımcı: Kişiselleştirme cümlesi üret -----
  String _buildPersonalization() {
    if (_babyName == null && _babyAgeKey == null) return '';
    final map = <String, String>{
      'newborn': '0-3 months old',
      'infant': '3-12 months old',
      'toddler': '1-3 years old',
      'preschool': '3-5 years old',
      'school': '5+ years old',
      'expecting': 'expecting (not born yet)',
    };
    String? ageText = _babyAgeKey != null
        ? (map[_babyAgeKey] ?? _babyAgeKey)
        : null;

    if (_babyName != null && ageText != null) {
      return '\n\nIMPORTANT PERSONALIZATION: The user\'s baby is named $_babyName and is $ageText. Please personalize your response accordingly and use the baby\'s name when appropriate.';
    } else if (_babyName != null) {
      return '\n\nIMPORTANT PERSONALIZATION: The user\'s baby is named $_babyName. Please personalize your response accordingly and use the baby\'s name when appropriate.';
    } else {
      return '\n\nIMPORTANT PERSONALIZATION: The user\'s baby is $ageText. Please personalize your response accordingly.';
    }
  }

  // =======================
  // 1) askMia
  // =======================
  /// Soru sorar; opsiyonel görseli (imageBytes + mimeType) ekleyebilirsin.
  /// Dönen değer: oluşturulan yanıt metni.
  Future<MiaAnswer?> askMia(
    String question, {
    Uint8List? imageBytes,
    String imageMimeType = 'image/png', // 'image/jpeg' vb.
    int maxTokens = 600,
    double temperature = 0.7,
  }) async {
    try {
      final system = '$_systemPrompt${_buildPersonalization()}';

      // Görseli hazırlama: desteklenmiyorsa PNG'e çevir
      Uint8List? sendBytes;
      String? sendMime;
      if (imageBytes != null) {
        final prepared = _ensureSupportedImage(imageBytes);
        sendBytes = prepared['bytes'] as Uint8List;
        sendMime = (prepared['mime'] as String).toLowerCase();
        if (sendMime == 'image/jpg') sendMime = 'image/jpeg'; // güvenlik
      }

      // Chat Completions şemasına uygun messages
      final List<Map<String, dynamic>> userContent = [
        {"type": "text", "text": question},
        if (sendBytes != null)
          {
            "type": "image_url",
            "image_url": {
              "url": "data:$sendMime;base64,${base64Encode(sendBytes)}",
            },
          },
      ];

      final body = {
        "model": _chatModel,
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": userContent},
        ],
        "max_tokens": maxTokens,
        "temperature": temperature,
      };

      final resp = await http
          .post(
            Uri.parse(_chatUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final raw = (data['choices'] as List?)?.isNotEmpty == true
            ? (data['choices'][0]['message']['content'] as String? ?? '')
            : '';

        if (raw.isEmpty) return null;

        // İçerik JSON olmak zorunda; parse edelim
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return MiaAnswer.fromMap(map);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // =======================
  // 2) getSuggestions
  // =======================
  /// Kullanıcının sorusuna göre 3 öneri döndürür (dilini de geç).
  Future<List<String>> getSuggestions({
    required String question,
    required String language,
    int maxTokens = 200,
    double temperature = 0.8,
  }) async {
    try {
      final body = {
        "model": _chatModel,
        "messages": [
          {"role": "system", "content": _suggestionsPrompt},
          {
            "role": "user",
            "content":
                'User\'s question: "$question"\nLanguage: $language\n\nProvide 3 related suggestions:',
          },
        ],
        "max_tokens": maxTokens,
        "temperature": temperature,
      };

      final resp = await http
          .post(
            Uri.parse(_chatUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final content = (data['choices'] as List?)?.isNotEmpty == true
            ? (data['choices'][0]['message']['content'] as String? ?? '')
            : '';
        if (content.isEmpty) return [];

        // Satırlara böl ve filtrele
        final lines = content
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(3)
            .toList();

        return lines;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // =======================
  // 3) transcribeAudio (Whisper)
  // =======================
  /// Ses dosyasını (bytes) Whisper ile çözümler.
  /// filename ve mimeType isteğe göre değiştirilebilir.
  Future<String> transcribeAudio(
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
    final uri = Uri.parse(_transcribeUrl);

    try {
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = model;

      // Opsiyonel parametreler (dökümantasyona uygun isimlerle)
      if (prompt != null && prompt.isNotEmpty) {
        req.fields['prompt'] = prompt;
      }
      if (language != null && language.isNotEmpty) {
        req.fields['language'] = language; // örn: "tr"
      }
      if (temperature != null) {
        req.fields['temperature'] = temperature.toString();
      }

      // Daha detaylı çıktı (segmentler vs.) istersen:
      // req.fields['response_format'] = 'verbose_json';

      // NOT: filename & mimeType gerçek formata yakın olsun
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamed = await req.send().timeout(timeout);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // response_format=verbose_json gönderdiysen 'text' + 'segments' olabilir
        return (data['text'] as String?) ?? '';
      } else {
        // Hata mesajını görsel olarak döndür (debug için)
        try {
          final err = jsonDecode(resp.body) as Map<String, dynamic>;
          final msg = (err['error'] is Map && err['error']['message'] is String)
              ? err['error']['message'] as String
              : resp.body;
          return 'Transcribe error (${resp.statusCode}): $msg';
        } catch (_) {
          return 'Transcribe error (${resp.statusCode})';
        }
      }
    } catch (e) {
      return 'Transcribe exception: $e';
    }
  }

  /// Bayttan basit MIME tespiti
  String _detectMime(Uint8List bytes) {
    if (bytes.length > 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47)
      return 'image/png';
    if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8)
      return 'image/jpeg';
    if (bytes.length > 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38)
      return 'image/gif';
    if (bytes.length > 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP')
      return 'image/webp';
    if (bytes.length > 2 && bytes[0] == 0x42 && bytes[1] == 0x4D)
      return 'image/bmp'; // BMP (desteklenmiyor)
    throw Exception('Unsupported image format');
  }

  /// Desteklenmeyen formatları (BMP vb.) PNG'e çevirir
  Map<String, dynamic> _ensureSupportedImage(Uint8List bytes) {
    final mime = _detectMime(bytes);
    const allowed = {'image/png', 'image/jpeg', 'image/gif', 'image/webp'};
    if (allowed.contains(mime)) {
      return {'bytes': bytes, 'mime': mime};
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Failed to decode image bytes');
    final pngBytes = Uint8List.fromList(img.encodePng(decoded));
    return {'bytes': pngBytes, 'mime': 'image/png'};
  }
}
