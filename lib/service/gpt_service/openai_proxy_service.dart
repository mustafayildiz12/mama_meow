import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

/// OpenAI çağrılarını Firebase Cloud Functions proxy'sine yönlendiren tek katman.
///
/// Anahtar artık istemcide değil (sunucu tarafında `OPENAI_API_KEY` secret'ı);
/// kimlik doğrulama ve kullanıcı başına günlük kota sunucuda uygulanır.
/// Bu sarmalayıcı, çağrı noktalarının eskiden okuduğu ham değerleri döndürür
/// (sohbet için `choices[0].message.content` string'i, transkripsiyon için `text`),
/// böylece prompt üretimi ve yanıt parse mantığı değişmeden kalır.
class OpenAiProxyService {
  // Varsayılan bölge us-central1 — fonksiyonların dağıtıldığı bölgeyle eşleşir.
  final FirebaseFunctions _fns = FirebaseFunctions.instance;

  static const Duration _timeout = Duration(seconds: 60);

  /// Sohbet (chat completions) proxy'si. Ham asistan içeriği string'ini döner;
  /// hata durumunda boş string.
  Future<String> chat({
    required List<Map<String, dynamic>> messages,
    required String model,
    required int maxTokens,
    required double temperature,
    Map<String, dynamic>? responseFormat,
  }) async {
    final callable = _fns.httpsCallable(
      'openaiChat',
      options: HttpsCallableOptions(timeout: _timeout),
    );
    final res = await callable.call<Map<String, dynamic>>({
      'messages': messages,
      'model': model,
      'maxTokens': maxTokens,
      'temperature': temperature,
      if (responseFormat != null) 'responseFormat': responseFormat,
    });
    return (res.data['content'] as String?) ?? '';
  }

  /// Whisper transkripsiyon proxy'si. Çözümlenen metni döner; hata durumunda
  /// boş string.
  Future<String> transcribe({
    required Uint8List audioBytes,
    String filename = 'audio.m4a',
    String mimeType = 'audio/mp4',
    String model = 'gpt-4o-mini-transcribe',
    String? language,
    String? prompt,
    double? temperature,
  }) async {
    final callable = _fns.httpsCallable(
      'openaiTranscribe',
      options: HttpsCallableOptions(timeout: _timeout),
    );
    final res = await callable.call<Map<String, dynamic>>({
      'audioBase64': base64Encode(audioBytes),
      'filename': filename,
      'mimeType': mimeType,
      'model': model,
      if (language != null) 'language': language,
      if (prompt != null) 'prompt': prompt,
      if (temperature != null) 'temperature': temperature,
    });
    return (res.data['text'] as String?) ?? '';
  }
}

final OpenAiProxyService openAiProxyService = OpenAiProxyService();
