/// Model (LLM) çıktısını ve RTDB'den gelen JSON'u hoşgörülü okumak için
/// küçük yardımcılar. Şema biraz kaysa bile (dizi yerine metin, sayı yerine
/// string vb.) tüm cevabı çöpe atmak yerine makul varsayılanlar döner.
library;

/// Herhangi bir değeri tek satır/paragraf metne çevirir.
/// - `null` → ''
/// - `List` → elemanlar alt alta birleştirilir
/// - `Map` → değerler birleştirilir
String jsonString(Object? v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is List) {
    return v.map(jsonString).where((s) => s.trim().isNotEmpty).join('\n');
  }
  if (v is Map) {
    return v.values
        .map(jsonString)
        .where((s) => s.trim().isNotEmpty)
        .join(' - ');
  }
  return v.toString();
}

/// Değeri metin listesine çevirir; boş elemanlar atlanır.
/// Tek bir metin gelirse satırlara bölünür.
List<String> jsonStringList(Object? v) {
  if (v == null) return const [];
  if (v is List) {
    return v
        .map(jsonString)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  final s = jsonString(v);
  return s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

/// Sayı veya sayısal metni int'e çevirir; çevrilemezse null.
int? jsonInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return num.tryParse(v.trim())?.toInt();
  return null;
}

/// `Map<Object?, Object?>` (RTDB) dahil her Map'i `Map<String, dynamic>`'e
/// çevirir; Map değilse null.
Map<String, dynamic>? jsonMap(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    return v.map((k, value) => MapEntry(k.toString(), value));
  }
  return null;
}

/// Liste değilse boş liste döner.
List<Object?> jsonList(Object? v) => v is List ? v : const [];
