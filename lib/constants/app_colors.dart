import 'package:flutter/material.dart';

/// Warm Cotton & Berry renk token'ları (docs/design/warm-cotton-berry/DESIGN.md).
/// Uygulamada yalnızca bu dosyadaki renkler kullanılır.
class AppColors {
  AppColors._();

  // ---- 5 marka rengi ----
  static const Color activeBerry = Color(0xFFFF6584);
  static const Color warmPink = Color(0xFFFFA6B5);
  static const Color peachPastel = Color(0xFFFFD0B8);
  static const Color cosyIvory = Color(0xFFFFF8F9);
  static const Color deepCharcoal = Color(0xFF3D353A);

  // ---- Türetilmiş tonlar ----
  static const Color cottonWhite = Color(0xFFFFFFFF);
  static const Color pinkTint = Color(0xFFFFE3E9);
  static const Color peachTint = Color(0xFFFFF0E8);

  /// Küçük vurgu metinleri (link, seçili sekme etiketi, fiyat). Ivory üzerinde 4.9:1.
  static const Color berryInk = Color(0xFFC7365A);

  /// İkincil metin, zaman damgası, placeholder.
  static const Color charcoalSoft = Color(0xFF6E6369);
  static const Color hairline = Color(0xFFF5E3E7);
  static const Color outline = Color(0xFFE8CDD3);
  static const Color scrim = Color(0x663D353A);

  /// Grafik seri sırası.
  static const List<Color> chartSeries = [
    activeBerry,
    warmPink,
    peachPastel,
    berryInk,
    charcoalSoft,
  ];

  /// Birincil butonun yumuşak berry parıltısı.
  static const List<BoxShadow> berryGlow = [
    BoxShadow(color: Color(0x4DFF6584), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Yüzen öğeler (sheet, FAB, alt menü) için gölge.
  static const List<BoxShadow> floatShadow = [
    BoxShadow(color: Color(0x143D353A), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
