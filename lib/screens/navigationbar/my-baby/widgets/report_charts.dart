import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/report_widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Rapor grafiklerinin ortak Warm Cotton & Berry stili.
class ReportChartStyle {
  ReportChartStyle._();

  static const axisLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoalSoft,
  );

  /// Sütun/çubuk ucundaki değer etiketleri (beyaz kart üzerinde berry ink).
  static const barDataLabels = DataLabelSettings(
    isVisible: true,
    labelAlignment: ChartDataLabelAlignment.outer,
    textStyle: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: AppColors.berryInk,
    ),
  );

  /// Halka grafik etiketleri: dilimin dışında, kömür renginde.
  static const pieDataLabels = DataLabelSettings(
    isVisible: true,
    labelPosition: ChartDataLabelPosition.outside,
    textStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.deepCharcoal,
    ),
    connectorLineSettings: ConnectorLineSettings(color: AppColors.outline),
  );

  static const legend = Legend(
    isVisible: true,
    overflowMode: LegendItemOverflowMode.wrap,
    iconHeight: 10,
    iconWidth: 10,
    textStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.deepCharcoal,
    ),
  );

  /// Sütunların üst köşeleri yuvarlak.
  static const columnRadius = BorderRadius.vertical(top: Radius.circular(8));

  /// Yatay çubukların değer ucu (sağ) yuvarlak.
  static const barRadius = BorderRadius.horizontal(right: Radius.circular(8));

  /// Kategori ekseni: çizgisiz, ızgarasız, yumuşak kömür etiketler.
  static CategoryAxis categoryAxis() => const CategoryAxis(
    majorGridLines: MajorGridLines(width: 0),
    majorTickLines: MajorTickLines(width: 0),
    axisLine: AxisLine(width: 0),
    labelStyle: axisLabelStyle,
  );

  /// Değer ekseni: ince pembe (hairline) ızgara.
  static NumericAxis valueAxis({String? labelFormat}) => NumericAxis(
    labelFormat: labelFormat,
    majorGridLines: const MajorGridLines(width: 1, color: AppColors.hairline),
    majorTickLines: const MajorTickLines(width: 0),
    axisLine: const AxisLine(width: 0),
    labelStyle: axisLabelStyle,
  );

  static TooltipBehavior tooltip() => TooltipBehavior(
    enable: true,
    color: AppColors.deepCharcoal,
    textStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.cottonWhite,
    ),
  );

  /// Kategori sırasına göre seri rengi (berry → pembe → şeftali → ink → kömür).
  static Color seriesColor(int index) =>
      AppColors.chartSeries[index % AppColors.chartSeries.length];
}

/// Dağılım halkası: dilimler seri sırasıyla (berry → pembe → şeftali …).
class DistributionDoughnut extends StatelessWidget {
  final List<ChartEntry> data;
  const DistributionDoughnut({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      backgroundColor: Colors.transparent,
      legend: ReportChartStyle.legend,
      series: <CircularSeries<ChartEntry, String>>[
        DoughnutSeries<ChartEntry, String>(
          dataSource: data,
          xValueMapper: (e, _) => e.label,
          yValueMapper: (e, _) => e.value,
          pointColorMapper: (_, i) => ReportChartStyle.seriesColor(i),
          innerRadius: '58%',
          radius: '78%',
          strokeColor: AppColors.cottonWhite,
          strokeWidth: 2,
          legendIconType: LegendIconType.circle,
          dataLabelSettings: ReportChartStyle.pieDataLabels,
          explode: true,
          explodeIndex: 0,
        ),
      ],
    );
  }
}
