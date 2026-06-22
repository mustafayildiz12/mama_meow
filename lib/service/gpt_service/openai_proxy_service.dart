import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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

  /// Sohbet (chat completions) proxy'si. Ham asistan içeriği string'ini döner.
  ///
  /// Hata durumunda callable hatasını analiz için loglar/Crashlytics'e kaydeder
  /// ve aynı hatayı yeniden fırlatır (çağıran katmanın mevcut `catch` mantığı
  /// korunur). Böylece "Mia couldn't answer" gibi genel mesajların altında
  /// gerçek sebep (örn. `not-found` = fonksiyon deploy edilmemiş,
  /// `unauthenticated`, `resource-exhausted` = günlük kota, `unavailable`)
  /// görünür olur.
  Future<String> chat({
    required List<Map<String, dynamic>> messages,
    required String model,
    required int maxTokens,
    required double temperature,
    Map<String, dynamic>? responseFormat,
  }) async {
    try {
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
    } on FirebaseFunctionsException catch (e, st) {
      _reportCallableError('openaiChat', e, st,
          code: e.code, details: e.details);
      rethrow;
    } catch (e, st) {
      _reportCallableError('openaiChat', e, st);
      rethrow;
    }
  }

  /// Whisper transkripsiyon proxy'si. Çözümlenen metni döner. Hata durumunda
  /// [chat] ile aynı şekilde loglar/Crashlytics'e kaydeder ve yeniden fırlatır.
  Future<String> transcribe({
    required Uint8List audioBytes,
    String filename = 'audio.m4a',
    String mimeType = 'audio/mp4',
    String model = 'gpt-4o-mini-transcribe',
    String? language,
    String? prompt,
    double? temperature,
  }) async {
    try {
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
    } on FirebaseFunctionsException catch (e, st) {
      _reportCallableError('openaiTranscribe', e, st,
          code: e.code, details: e.details);
      rethrow;
    } catch (e, st) {
      _reportCallableError('openaiTranscribe', e, st);
      rethrow;
    }
  }

  /// Callable hatasını analiz için detaylı loglar: debug konsoluna
  /// (`dart:developer`) yazar ve Crashlytics'e non-fatal olarak kaydeder.
  /// [code] ve [details] yalnızca `FirebaseFunctionsException` için doludur.
  void _reportCallableError(
    String fn,
    Object error,
    StackTrace st, {
    String? code,
    Object? details,
  }) {
    developer.log(
      'OpenAI proxy "$fn" failed (code=$code, details=$details)',
      name: 'OpenAiProxyService',
      error: error,
      stackTrace: st,
    );
    FirebaseCrashlytics.instance.recordError(
      error,
      st,
      reason: 'OpenAiProxyService.$fn (code=$code)',
      fatal: false,
    );
  }
}

final OpenAiProxyService openAiProxyService = OpenAiProxyService();
