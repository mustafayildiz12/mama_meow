/// Aktivite PDF raporlarının ortak yapı taşları: tema/font, başlık, özet
/// kartları, AI bloğu, tablo, alt bilgi ve biçimlendiriciler.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ---- Warm Cotton & Berry PDF renkleri ----
// PdfColor, Flutter Color'dan farklı bir tür olduğu için değerler burada
// tekrar tanımlanır (kaynak: lib/constants/app_colors.dart). Hex değer
// barındıran tek PDF dosyası budur.
const _berry = PdfColor.fromInt(0xFFFF6584);
const _warmPink = PdfColor.fromInt(0xFFFFA6B5);
const _peach = PdfColor.fromInt(0xFFFFD0B8);
const _ivory = PdfColor.fromInt(0xFFFFF8F9);
const _charcoal = PdfColor.fromInt(0xFF3D353A);
const _charcoalSoft = PdfColor.fromInt(0xFF6E6369);
const _berryInk = PdfColor.fromInt(0xFFC7365A);
const _hairline = PdfColor.fromInt(0xFFF5E3E7);
const _outline = PdfColor.fromInt(0xFFE8CDD3);
const _pinkTint = PdfColor.fromInt(0xFFFFE3E9);
const _peachTint = PdfColor.fromInt(0xFFFFF0E8);
const _white = PdfColor.fromInt(0xFFFFFFFF);

/// PDF raporlarının Berry paleti. Rapor oluşturucular renklerini yalnızca
/// buradan (ya da [ReportPdfTheme] üzerinden) alır.
class ReportPdfColors {
  ReportPdfColors._();

  static const PdfColor berry = _berry;
  static const PdfColor warmPink = _warmPink;
  static const PdfColor peach = _peach;
  static const PdfColor ivory = _ivory;
  static const PdfColor charcoal = _charcoal;
  static const PdfColor charcoalSoft = _charcoalSoft;
  static const PdfColor berryInk = _berryInk;
  static const PdfColor hairline = _hairline;
  static const PdfColor outline = _outline;
  static const PdfColor pinkTint = _pinkTint;
  static const PdfColor peachTint = _peachTint;
  static const PdfColor white = _white;

  /// Grafik seri sırası (uygulamadaki AppColors.chartSeries ile aynı).
  static const List<PdfColor> chartSeries = [
    _berry,
    _warmPink,
    _peach,
    _berryInk,
    _charcoalSoft,
  ];
}

/// Rapor renkleri + Nunito fontları.
///
/// Belge teması Nunito'dur; varsayılan Helvetica yalnızca Latin-1 içerdiği
/// için Türkçe karakterler (ş, ğ, ı) tablolarda kayboluyordu.
///
/// Tüm raporlar aynı Warm Cotton & Berry paletini kullanır; aktiviteye özel
/// renk yoktur.
class ReportPdfTheme {
  ReportPdfTheme._({
    required this.regular,
    required this.semiBold,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font semiBold;
  final pw.Font bold;

  /// Vurgu rengi (madde işaretleri, başlık çizgisi).
  PdfColor get accent => ReportPdfColors.berry;

  /// Küçük vurgu metinleri (bölüm etiketleri).
  PdfColor get accentText => ReportPdfColors.berryInk;

  /// Ana metin.
  PdfColor get text => ReportPdfColors.charcoal;

  /// İkincil metin (alt başlık, tarih, açıklama).
  PdfColor get textSoft => ReportPdfColors.charcoalSoft;

  /// Kart ve tablo çizgileri.
  PdfColor get line => ReportPdfColors.outline;

  /// Tablo başlık satırı zemini.
  PdfColor get tableHeader => ReportPdfColors.pinkTint;

  /// Tablonun çift satır zemini.
  PdfColor get scaffold => ReportPdfColors.ivory;

  /// AI analiz bloğu zemini (uygulamadaki "Meow's insight" kartı gibi).
  PdfColor get insight => ReportPdfColors.peachTint;

  static const String _fontDir = 'assets/fonts/nunito';

  // Font baytları uygulama boyunca bir kez yüklenir.
  static final Map<String, Future<ByteData>> _fontCache = {};

  static Future<ByteData> _font(String file) {
    return _fontCache.putIfAbsent(file, () {
      final future = rootBundle.load('$_fontDir/$file');
      // Hata olursa önbellekten çıkar ki sonraki deneme yeniden yüklesin.
      future.catchError((Object _) {
        _fontCache.remove(file);
        return ByteData(0);
      });
      return future;
    });
  }

  static Future<ReportPdfTheme> load() async {
    final data = await Future.wait([
      _font('Nunito-Regular.ttf'),
      _font('Nunito-SemiBold.ttf'),
      _font('Nunito-Bold.ttf'),
    ]);
    return ReportPdfTheme._(
      regular: pw.Font.ttf(data[0]),
      semiBold: pw.Font.ttf(data[1]),
      bold: pw.Font.ttf(data[2]),
    );
  }

  /// Başlık kartının yumuşak pembe → şeftali zemini.
  pw.LinearGradient get gradient => const pw.LinearGradient(
    begin: pw.Alignment.topLeft,
    end: pw.Alignment.bottomRight,
    colors: [ReportPdfColors.pinkTint, ReportPdfColors.peachTint],
  );

  /// Belgedeki tüm metinler (tablolar dahil) için Nunito.
  pw.ThemeData get documentTheme =>
      pw.ThemeData.withFont(base: regular, bold: bold);
}

/// Tek sayfa akışlı (MultiPage) rapor belgesi üretir.
Future<Uint8List> buildReportPdf({
  required PdfPageFormat format,
  required ReportPdfTheme theme,
  required List<pw.Widget> Function(pw.Context context) build,
}) async {
  final doc = pw.Document(theme: theme.documentTheme);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(24),
      build: build,
    ),
  );
  return Uint8List.fromList(await doc.save());
}

/// "Daily Sleep Report" gibi başlık.
String reportTitle(ReportPeriod period, String subject) {
  final prefix = switch (period) {
    ReportPeriod.today => 'Daily',
    ReportPeriod.week => 'Weekly',
    ReportPeriod.month => 'Monthly',
  };
  return '$prefix $subject Report';
}

pw.Widget pdfHeader(
  ReportPdfTheme t, {
  required String title,
  required String subtitle,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: ReportPdfColors.hairline),
      gradient: t.gradient,
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: t.semiBold,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: t.text,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  font: t.regular,
                  fontSize: 11,
                  color: t.textSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Özet kartı: (başlık, değer).
typedef PdfStat = (String label, String value);

pw.Widget pdfSummaryCards(
  ReportPdfTheme t,
  List<PdfStat> stats, {
  double valueFontSize = 14,
}) {
  pw.Widget card(PdfStat s) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      // Uygulamadaki özet kartları gibi: beyaz zemin, ince pembe çizgi.
      decoration: pw.BoxDecoration(
        color: ReportPdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: t.line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            s.$1,
            style: pw.TextStyle(
              font: t.regular,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: t.textSoft,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            s.$2,
            style: pw.TextStyle(
              font: t.semiBold,
              fontSize: valueFontSize,
              fontWeight: pw.FontWeight.bold,
              color: t.text,
            ),
          ),
        ],
      ),
    ),
  );

  return pw.Row(
    children: [
      for (var i = 0; i < stats.length; i++) ...[
        if (i > 0) pw.SizedBox(width: 10),
        card(stats[i]),
      ],
    ],
  );
}

/// AI analiz bloğu (tablonun üstünde). Emojiler (font çizemez) temizlenir.
pw.Widget pdfAiBlock(
  ReportPdfTheme t,
  AiReportInsight ai, {
  required String fallbackTitle,
  String fallbackDisclaimer =
      'Not medical advice. Consult a healthcare professional for concerns.',
}) {
  List<String> clean(List<String> items) => items
      .map(stripEmojis)
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final title = stripEmojis(ai.aiTitle).trim();
  final confidence = stripEmojis(ai.confidenceNote).trim();
  final disclaimer = stripEmojis(ai.disclaimer).trim();
  final sourceLines = ai.sources
      .take(2)
      .map((s) => stripEmojis(s.displayLine).trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final small = pw.TextStyle(
    font: t.regular,
    fontSize: 10,
    color: t.textSoft,
  );
  pw.Widget heading(String text) => pw.Text(
    text,
    style: pw.TextStyle(font: t.semiBold, fontSize: 11, color: t.accentText),
  );

  pw.Widget bullets(String head, List<String> items) {
    if (items.isEmpty) return pw.SizedBox();
    final style = pw.TextStyle(font: t.regular, fontSize: 10, color: t.text);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        heading(head),
        pw.SizedBox(height: 4),
        for (final it in items.take(6))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('•  ', style: style.copyWith(color: t.accent)),
                pw.Expanded(child: pw.Text(it, style: style)),
              ],
            ),
          ),
      ],
    );
  }

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    // Uygulamadaki "Meow's insight" kartı gibi şeftali zemin.
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: ReportPdfColors.peach),
      color: t.insight,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.isNotEmpty ? title : fallbackTitle,
          style: pw.TextStyle(
            font: t.semiBold,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: t.text,
          ),
        ),
        bullets('Summary', clean(ai.aiSummaryBullets)),
        bullets('Patterns', clean(ai.patterns)),
        bullets('Watch outs', clean(ai.watchOuts)),
        bullets('Action plan', clean(ai.actionPlan)),
        if (confidence.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          heading('Confidence'),
          pw.SizedBox(height: 3),
          pw.Text(confidence, style: small),
        ],
        pw.SizedBox(height: 8),
        pw.Text(
          disclaimer.isNotEmpty ? disclaimer : fallbackDisclaimer,
          style: small.copyWith(fontSize: 9),
        ),
        if (sourceLines.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          heading('Sources'),
          pw.SizedBox(height: 3),
          for (final line in sourceLines)
            pw.Text(line, style: small.copyWith(fontSize: 8)),
        ],
      ],
    ),
  );
}

pw.Widget pdfSectionTitle(ReportPdfTheme t, String text) => pw.Text(
  text,
  style: pw.TextStyle(
    font: t.semiBold,
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
    color: t.text,
  ),
);

pw.Widget pdfTable(
  ReportPdfTheme t, {
  required List<String> headers,
  required List<List<String>> rows,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(
      font: t.bold,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: t.text,
    ),
    cellStyle: pw.TextStyle(font: t.regular, fontSize: 9, color: t.text),
    // Başlık pembe tint, satırlar beyaz / ivory dönüşümlü.
    headerDecoration: pw.BoxDecoration(color: t.tableHeader),
    rowDecoration: const pw.BoxDecoration(color: ReportPdfColors.white),
    oddRowDecoration: pw.BoxDecoration(color: t.scaffold),
    cellAlignment: pw.Alignment.center,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    border: pw.TableBorder.all(color: t.line, width: 0.6),
  );
}

pw.Widget pdfGeneratedAt(ReportPdfTheme t, {DateTime? now}) => pw.Text(
  'Generated at: ${DateFormat('yyyy-MM-dd HH:mm').format(now ?? DateTime.now())}',
  style: pw.TextStyle(font: t.regular, fontSize: 10, color: t.textSoft),
);

/// Dakika → "0m", "45m", "2h", "2h 5m".
String fmtDurationMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// 5 → "5", 5.0 → "5", 5.25 → "5.25", 1.50 → "1.5".
String fmtNumber(num v) {
  final d = v.toDouble();
  if ((d - d.roundToDouble()).abs() < 1e-6) return d.round().toString();
  var s = d.toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// yyyy-MM-dd; null ise "-".
String fmtPdfDate(DateTime? d) =>
    d == null ? '-' : DateFormat('yyyy-MM-dd').format(d);

/// HH:mm; null ise "-".
String fmtPdfTime(DateTime? d) =>
    d == null ? '-' : DateFormat('HH:mm').format(d);

final RegExp _emojiPattern = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{1F1E6}-\u{1F1FF}\u{FE0E}\u{FE0F}\u{200D}\u{20E3}]',
  unicode: true,
);

/// PDF fontunun çizemediği emoji ve birleştiricileri siler; kalan çift
/// boşlukları sadeleştirir.
String stripEmojis(String s) =>
    s.replaceAll(_emojiPattern, '').replaceAll(RegExp(r'[ \t]{2,}'), ' ');
