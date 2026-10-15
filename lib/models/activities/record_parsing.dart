/// RTDB aktivite kayıtlarını hoşgörülü okumak için yardımcılar.
///
/// Eski sürümler bazı alanları farklı tiplerde yazmış olabilir (ör. ilaç
/// `amount` int, mama miktarı String). Tek bir bozuk alan yüzünden kaydın
/// (ve raporun) düşmemesi için cast yerine bunlar kullanılır.
library;

String recordString(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

String? recordStringOrNull(Object? v) => v?.toString();

/// Sayı veya sayısal metin ("1,5" dahil) → num; okunamazsa [fallback].
num recordNum(Object? v, [num fallback = 0]) => parseLooseNum(v) ?? fallback;

int recordInt(Object? v, [int fallback = 0]) =>
    parseLooseNum(v)?.toInt() ?? fallback;

bool recordBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    switch (v.trim().toLowerCase()) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
    }
  }
  return fallback;
}

/// "1.5", "1,5", 2, 2.0 → num; aksi halde null.
num? parseLooseNum(Object? v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim().replaceAll(',', '.'));
  return null;
}

/// ISO-8601 `createdAt` metnini çözer; boş/geçersizse null.
DateTime? parseCreatedAt(String createdAt) =>
    createdAt.trim().isEmpty ? null : DateTime.tryParse(createdAt.trim());
