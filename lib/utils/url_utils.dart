import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dış bağlantılar için tek nokta. AI cevaplarından veya veritabanından
/// gelen adresler güvenilir değildir; yalnızca http/https açılır.
abstract final class UrlUtils {
  /// [url] açılabilir bir http/https adresi mi.
  static bool isWebUrl(String? url) => _parse(url) != null;

  /// [url]'yi harici uygulamada (tarayıcı) açar. Geçersiz adres ya da
  /// açılamama durumunda false döner; hata fırlatmaz.
  static Future<bool> openExternal(String? url) async {
    final uri = _parse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('UrlUtils.openExternal failed: $e');
      return false;
    }
  }

  static Uri? _parse(String? url) {
    final uri = Uri.tryParse(url?.trim() ?? '');
    if (uri == null || uri.host.isEmpty) return null;
    if (!uri.isScheme('http') && !uri.isScheme('https')) return null;
    return uri;
  }
}
