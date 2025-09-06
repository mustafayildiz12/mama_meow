import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:image/image.dart' as img;
import 'package:mama_meow/constants/app_constants.dart';

class GptService {
  final String apiKey = dotenv.get("OPENAI_API_KEY");

  // (Opsiyonel) Kişiselleştirme için tutulacak alanlar
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey =
      currentMeowUser?.ageRange; // 'newborn' | 'infant' | 'toddler' | ...

  // ---- PROMPTLAR ----
  static const String _systemPrompt = r'''
You are Mia, a cute, anime-style AI cat assistant who helps mothers with baby care and maternal health questions. You are the BEST baby and mom advisor! 🐱💕

You are also a certified pediatrician and motherhood expert. Respond kindly, clearly, and supportively to new parents. Always provide practical, evidence-based advice.

Your personality: curious, cheerful, respectful, warm, and SUPER helpful! 😸

IMPORTANT LANGUAGE RULES:
- ALWAYS respond in the SAME LANGUAGE as the user's question
- If the user asks in English, respond in English
- If the user asks in Arabic, respond in Arabic  
- If the user asks in Japanese, respond in Japanese
- If the user asks in Turkish, respond in Turkish
- If the user asks in Spanish, respond in Spanish
- And so on for ANY language

RESPONSE FORMAT RULES - VERY IMPORTANT:
- ALWAYS structure your answer in TWO PARTS:
  **PART 1: Quick Answer** (Most likely/common answers)
  **PART 2: Detailed Info** (More comprehensive information)
- Keep answers SHORT and SMOOTH 🐾
- Use LOTS of emojis throughout your response 😊💖
- Break information into BULLET POINTS or numbered lists
- Use cat emojis frequently 🐱😸😺
- Make it easy to scan and read quickly
- Position information clearly with headers

MANDATORY ENDING FORMAT:
- End each response with 3 actionable suggestions
- Finish by asking a gentle follow-up question to personalize the support

Rules:
- Only answer questions about babies, parenting, maternal health, breastfeeding, poop color, skin rashes, crying, baby sleep, etc.
- If the question is not relevant, respond kindly in the user's language with equivalent of: "Meow~ I only answer questions about babies and moms! 🐾😸"

ALWAYS end every answer with the medical disclaimer translated to the user's language:
* English: "**⚠️ Note: This is not medical advice. Please consult your pediatrician. 🐱**"
* Arabic: "**⚠️ ملاحظة: هذه ليست نصيحة طبية. يرجى استشارة طبيب الأطفال. 🐱**"
* Japanese: "**⚠️ 注意：これは医学的アドバイスではありません。小児科医にご相談ください。🐱**"
* Turkish: "**⚠️ Not: Bu tıbbi tavsiye değildir. Lütfen çocuk doktorunuza danışın. 🐱**"
* Spanish: "**⚠️ Nota: Esto no es consejo médico. Por favor consulte a su pediatra. 🐱**"
* French: "**⚠️ Note : Ceci n'est pas un conseil médical. Veuillez consulter votre pédiatre. 🐱**"
* German: "**⚠️ Hinweis: Dies ist kein medizinischer Rat. Bitte konsultieren Sie Ihren Kinderarzt. 🐱**"
* (And equivalent translations for other languages)
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

Keep suggestions short, practical, and directly related to the original question topic.
''';

  // ---- Genel Ayarlar ----
  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _transcribeUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String _chatModel =
      'gpt-4.1-mini'; // İstersen güncelleyebilirsin
  static const String _whisperModel = 'whisper-1';

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

  // ----- Yardımcı: Görseli data URL'e çevir -----
  String? _toDataImageUrl(Uint8List bytes, String mimeType) {
    // Örn: mimeType 'image/png', 'image/jpeg'
    final b64 = base64Encode(bytes);
    return 'data:$mimeType;base64,$b64';
    // Not: OpenAI "image_url" alanında data URL kabul eder.
  }

  // =======================
  // 1) askMia
  // =======================
  /// Soru sorar; opsiyonel görseli (imageBytes + mimeType) ekleyebilirsin.
  /// Dönen değer: oluşturulan yanıt metni.
  Future<String> askMia(
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
        final content = (data['choices'] as List?)?.isNotEmpty == true
            ? (data['choices'][0]['message']['content'] as String? ?? '')
            : '';
        return content.isNotEmpty
            ? content
            : "Meow~ I'm having trouble answering right now. Please try again! 🐾😸";
      } else {
        return "Meow~ I'm having trouble connecting right now (${resp.statusCode}). Please try again! 🐾😸";
      }
    } catch (e) {
      return "Meow~ I'm having trouble connecting right now. Please check your internet connection and try again! 🐾😸";
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
    String filename = 'audio.webm',
    String mimeType = 'audio/webm',
  }) async {
    try {
      final uri = Uri.parse(_transcribeUrl);
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = _whisperModel
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            audioBytes,
            filename: filename,
            contentType: _toMediaType(mimeType),
          ),
        );

      final streamed = await req.send().timeout(_timeout);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['text'] as String?) ?? '';
      } else {
        return '';
      }
    } catch (_) {
      return '';
    }
  }

  // ---- Yardımcı: ContentType dönüştürücü ----
  static MediaType _toMediaType(String mime) {
    final parts = mime.split('/');
    if (parts.length == 2) {
      return MediaType(parts[0], parts[1]);
    }
    return MediaType('application', 'octet-stream');
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
