import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mama_meow/service/gpt_service/gpt_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum VoiceStartResult { started, permissionDenied, failed }

/// Ask Meow'daki sesli soru: kayıt, süre/seviye göstergesi ve metne çevirme.
/// Geçici .m4a dosyası kullanım sonrası silinir.
class VoiceRecorderController extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  String? _currentPath;
  bool _disposed = false;

  bool _isRecording = false;
  bool _isTranscribing = false;
  Duration _elapsed = Duration.zero;
  double _amplitude = 0;

  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  bool get isBusy => _isRecording || _isTranscribing;
  Duration get elapsed => _elapsed;

  /// 0..1 arası normalize ses seviyesi.
  double get amplitude => _amplitude;

  Future<VoiceStartResult> start() async {
    if (isBusy) return VoiceStartResult.failed;
    try {
      if (!await _recorder.hasPermission()) {
        return VoiceStartResult.permissionDenied;
      }

      // Kayıt dosya yolu (m4a kapsayıcı, AAC)
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'rec_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      if (_disposed) return VoiceStartResult.failed;
      _currentPath = path;

      // Görsel geri bildirim: -60..0 dB → 0..1
      await _ampSub?.cancel();
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((a) {
            _amplitude = ((a.current + 60) / 60).clamp(0, 1).toDouble();
            _notify();
          });

      _timer?.cancel();
      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed += const Duration(seconds: 1);
        _notify();
      });

      _isRecording = true;
      _notify();
      return VoiceStartResult.started;
    } catch (e) {
      debugPrint('VoiceRecorder start failed: $e');
      await _stopTicking();
      return VoiceStartResult.failed;
    }
  }

  /// Kaydı durdurur ve metne çevirir. Başarısızsa (veya metin boşsa) null.
  Future<String?> stopAndTranscribe() async {
    if (!_isRecording) return null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('VoiceRecorder stop failed: $e');
    }
    path ??= _currentPath;
    _currentPath = null;
    await _stopTicking();
    _isRecording = false;
    _amplitude = 0;

    if (path == null) {
      _notify();
      return null;
    }

    _isTranscribing = true;
    _notify();
    try {
      final bytes = await File(path).readAsBytes();
      return _nonEmpty(
        await GptService().transcribeAudio(
          bytes,
          filename: p.basename(path),
          mimeType: 'audio/mp4', // m4a/AAC için doğru MIME
        ),
      );
    } catch (e) {
      debugPrint('VoiceRecorder transcribe failed: $e');
      return null;
    } finally {
      _isTranscribing = false;
      await _deleteFile(path);
      _notify();
    }
  }

  /// Servis hata durumunda null döner; boş metni de başarısız say.
  static String? _nonEmpty(String? text) {
    final trimmed = text?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _stopTicking() async {
    _timer?.cancel();
    _timer = null;
    await _ampSub?.cancel();
    _ampSub = null;
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('VoiceRecorder temp file delete failed: $e');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _ampSub?.cancel();
    final pending = _currentPath;
    _currentPath = null;
    unawaited(_disposeRecorder(pending));
    super.dispose();
  }

  /// Yarım kalan kaydı durdurur (dispose bunu yapar) ve geçici dosyayı siler.
  Future<void> _disposeRecorder(String? pendingPath) async {
    try {
      await _recorder.dispose();
    } catch (e) {
      debugPrint('VoiceRecorder dispose failed: $e');
    }
    if (pendingPath != null) await _deleteFile(pendingPath);
  }
}
