import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/review_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_loader.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Rapor başlığında gösterilen dönem etiketi.
String reportRangeLabel(ReportPeriod period, [DateTime? now]) {
  final n = now ?? DateTime.now();
  switch (period) {
    case ReportPeriod.today:
      return DateFormat('EEEE, d MMM').format(n);
    case ReportPeriod.week:
      final a = DateFormat('d MMM').format(n.startOfWeekTR);
      final b = DateFormat('d MMM').format(n.endOfWeekTR);
      return "$a – $b";
    case ReportPeriod.month:
      final a = DateFormat('MMM yyyy').format(n.startOfMonth);
      final b = DateFormat('d').format(n.endOfMonth);
      return "$a (1–$b)";
  }
}

/// PDF dosya adı: `<prefix>_daily_dd_MM_yyyy.pdf` vb.
String reportPdfFileName(String prefix, ReportPeriod period, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final f = DateFormat('dd_MM_yyyy');
  switch (period) {
    case ReportPeriod.today:
      return '${prefix}_daily_${f.format(n)}.pdf';
    case ReportPeriod.week:
      return '${prefix}_weekly_${f.format(n.startOfWeekTR)}_${f.format(n.endOfWeekTR)}.pdf';
    case ReportPeriod.month:
      return '${prefix}_monthly_${DateFormat('MM_yyyy').format(n)}.pdf';
  }
}

/// Kaydın gerçek olay zamanı: kaydetme anı ([createdAt]) + kullanıcının seçtiği
/// "HH:mm". createdAt okunamazsa yalnızca saat (0. yıl) döner.
DateTime reportEventTime(String createdAt, String? hhmm) {
  final saved = DateTime.tryParse(createdAt);
  if (saved != null) return resolveEventTime(saved, hhmm);
  final hm = parseHourMinute(hhmm);
  return DateTime(0, 1, 1, hm?.$1 ?? 0, hm?.$2 ?? 0);
}

/// Rapor sayfalarının ortak durumu: dönem seçimi, veri çekme, hesap önbelleği
/// ve "PDF oluştur + paylaş" akışı.
///
/// [T] kayıt modeli, [C] sayfanın hesapladığı rapor özeti.
mixin ReportPageMixin<W extends StatefulWidget, T, C> on State<W> {
  ReportPeriod period = ReportPeriod.today;
  late Future<List<T>> future;

  /// PDF hazırlanırken tam ekran yükleyici gösterilir.
  bool exporting = false;

  List<T>? _cachedItems;
  C? _cachedComputed;
  ReportPeriod? _cachedPeriod;

  /// Seçili dönemin kayıtlarını getirir.
  Future<List<T>> fetchFor(ReportPeriod period);

  /// Kayıtlardan rapor özetini hesaplar.
  C computeReport(List<T> items);

  String get rangeLabel => reportRangeLabel(period);

  /// `initState` içinde, `super.initState()` sonrasında çağrılır.
  void initReport(String screenName) {
    future = fetchFor(period);
    analyticService.screenView(screenName);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.cosyIvory,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  void changePeriod(ReportPeriod p) {
    setState(() {
      period = p;
      future = fetchFor(p);
      _clearCache();
    });
  }

  Future<void> refreshReport() async {
    setState(() {
      future = fetchFor(period);
      _clearCache();
    });
    try {
      await future;
    } catch (_) {
      // Hata FutureBuilder'da gösteriliyor.
    }
  }

  void _clearCache() {
    _cachedItems = null;
    _cachedComputed = null;
    _cachedPeriod = null;
  }

  /// Aynı liste ve dönem için özeti bir kez hesaplar (UI + PDF ortak).
  C computedFor(List<T> items) {
    final cached = _cachedComputed;
    if (cached != null &&
        _cachedPeriod == period &&
        identical(_cachedItems, items)) {
      return cached;
    }
    final c = computeReport(items);
    _cachedItems = items;
    _cachedComputed = c;
    _cachedPeriod = period;
    return c;
  }

  /// PDF'i oluşturup paylaşım sayfasını açar. [anchor] iPad'de paylaşım
  /// popover'ının konumu içindir (PDF butonunun context'i).
  Future<void> exportPdf(
    BuildContext anchor, {
    required String filePrefix,
    required String emptyMessage,
    required String shareText,
    required Future<Uint8List> Function(
      List<T> items,
      C computed,
      ReportPeriod period,
      String rangeLabel,
    )
    buildPdf,
  }) async {
    if (exporting) return;
    final p = period;
    final label = reportRangeLabel(p);
    setState(() => exporting = true);
    try {
      final items = _cachedItems ?? await future;
      if (!mounted) return;
      if (items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emptyMessage)));
        return;
      }

      final bytes = await buildPdf(items, computedFor(items), p, label);
      final path = await globalFunctions.downloadBytes(
        bytes,
        reportPdfFileName(filePrefix, p),
      );
      if (!mounted) return;
      await globalFunctions.sharePdf(
        path,
        text: shareText,
        context: anchor.mounted ? anchor : null,
      );
      await reviewService.recordPositiveMomentAndMaybeAsk();
    } catch (e, st) {
      debugPrint('Report PDF export failed: $e\n$st');
      customSnackBar.warning(
        "We couldn't create the PDF report. Please try again.",
      );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }
}

/// Rapor sayfalarının ortak iskeleti: AppBar (geri + PDF), dönem seçici,
/// FutureBuilder ile yükleniyor / hata / boş / içerik durumları.
class ReportScaffold<T> extends StatelessWidget {
  const ReportScaffold({
    super.key,
    required this.title,
    this.palette = ReportPalette.berry,
    this.pdfIconColor,
    required this.isLoading,
    required this.onExportPdf,
    required this.onRefresh,
    required this.period,
    required this.onPeriodChanged,
    required this.future,
    required this.empty,
    required this.builder,
    this.bottomSafeArea = false,
  });

  final String title;
  final ReportPalette palette;

  /// Eski parametre; paylaşım ikonu her zaman koyu kömür rengindedir.
  final Color? pdfIconColor;
  final bool isLoading;

  /// PDF butonu yalnızca giriş yapmış kullanıcıya gösterilir.
  final void Function(BuildContext anchor) onExportPdf;
  final Future<void> Function() onRefresh;
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final Future<List<T>> future;

  /// Seçili dönemde kayıt yokken gösterilen mesaj.
  final Widget empty;
  final Widget Function(BuildContext context, List<T> items) builder;
  final bool bottomSafeArea;

  @override
  Widget build(BuildContext context) {
    final user = authenticationService.getUser();

    final body = RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: RangeSegmented(value: period, onChanged: onPeriodChanged),
          ),
          Expanded(
            child: FutureBuilder<List<T>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  return const CenteredMessage.loadError();
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) return empty;
                return builder(context, items);
              },
            ),
          ),
        ],
      ),
    );

    return CustomLoader(
      inAsyncCall: isLoading,
      child: ReportPaletteScope(
        palette: palette,
        child: Scaffold(
          backgroundColor: AppColors.cosyIvory,
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            title: Text(title),
            actions: [
              if (user != null)
                Builder(
                  builder: (anchor) => IconButton(
                    tooltip: 'Export PDF',
                    icon: const Icon(Icons.ios_share),
                    onPressed: () => onExportPdf(anchor),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: bottomSafeArea ? SafeArea(top: false, child: body) : body,
        ),
      ),
    );
  }
}
