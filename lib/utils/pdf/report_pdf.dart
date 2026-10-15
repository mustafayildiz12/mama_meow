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

/// Rapor renkleri + Nunito fontları.
///
/// Belge teması Nunito'dur; varsayılan Helvetica yalnızca Latin-1 içerdiği
/// için Türkçe karakterler (ş, ğ, ı) tablolarda kayboluyordu.
class ReportPdfTheme {
  ReportPdfTheme._({
    required this.regular,
    required this.semiBold,
    required this.bold,
    required this.accent,
    required this.gradientEnd,
    required this.scaffold,
  });

  final pw.Font regular;
  final pw.Font semiBold;
  final pw.Font bold;

  /// Kart/başlık rengi (tablo başlığı da bu renk).
  final PdfColor accent;

  /// Gradyanın bittiği renk.
  final PdfColor gradientEnd;

  /// Tablo satırı ve AI bloğu zemini.
  final PdfColor scaffold;

  static const PdfColor defaultScaffold = PdfColor(
    0.9725490196,
    0.9803921569,
    0.9882352941,
  );

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

  static Future<ReportPdfTheme> load({
    required PdfColor accent,
    PdfColor gradientEnd = PdfColors.white,
    PdfColor scaffold = defaultScaffold,
  }) async {
    final data = await Future.wait([
      _font('Nunito-Regular.ttf'),
      _font('Nunito-SemiBold.ttf'),
      _font('Nunito-Bold.ttf'),
    ]);
    return ReportPdfTheme._(
      regular: pw.Font.ttf(data[0]),
      semiBold: pw.Font.ttf(data[1]),
      bold: pw.Font.ttf(data[2]),
      accent: accent,
      gradientEnd: gradientEnd,
      scaffold: scaffold,
    );
  }

  pw.LinearGradient get gradient => pw.LinearGradient(
    begin: pw.Alignment.topLeft,
    end: pw.Alignment.bottomRight,
    colors: [accent, gradientEnd],
    stops: const [0.2, 1.0],
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
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColors.grey300),
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
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  font: t.regular,
                  fontSize: 11,
                  color: PdfColors.grey700,
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
      decoration: pw.BoxDecoration(
        gradient: t.gradient,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
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
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            s.$2,
            style: pw.TextStyle(
              font: t.semiBold,
              fontSize: valueFontSize,
              fontWeight: pw.FontWeight.bold,
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
    color: PdfColors.grey700,
  );
  pw.Widget heading(String text) =>
      pw.Text(text, style: pw.TextStyle(font: t.semiBold, fontSize: 11));

  pw.Widget bullets(String head, List<String> items) {
    if (items.isEmpty) return pw.SizedBox();
    final style = pw.TextStyle(font: t.regular, fontSize: 10);
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
                pw.Text('•  ', style: style),
                pw.Expanded(child: pw.Text(it, style: style)),
              ],
            ),
          ),
      ],
    );
  }

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColors.grey300),
      color: t.scaffold,
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
    ),
    cellStyle: pw.TextStyle(font: t.regular, fontSize: 9),
    headerDecoration: pw.BoxDecoration(color: t.accent),
    rowDecoration: pw.BoxDecoration(color: t.scaffold),
    cellAlignment: pw.Alignment.center,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
  );
}

pw.Widget pdfGeneratedAt(ReportPdfTheme t, {DateTime? now}) => pw.Text(
  'Generated at: ${DateFormat('yyyy-MM-dd HH:mm').format(now ?? DateTime.now())}',
  style: pw.TextStyle(font: t.regular, fontSize: 10, color: PdfColors.grey700),
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
