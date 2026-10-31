import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/format.dart';
import '../../../../core/theme.dart';
import '../../domain/models.dart';

/// Interactive line chart: touch/drag shows a crosshair tooltip with price + time.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points, required this.range});
  final List<ChartPoint> points;
  final ChartRange range;

  @override
  Widget build(BuildContext context) {
    final up = points.last.price >= points.first.price;
    final color = up ? AppColors.up : AppColors.down;
    final prices = points.map((p) => p.price);
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.08;
    final dateFmt = range == ChartRange.d1 ? DateFormat('HH:mm') : DateFormat('d MMM');

    return LineChart(
      duration: const Duration(milliseconds: 250),
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.5, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 4).floorToDouble().clamp(1, double.infinity),
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(dateFmt.format(points[i].time),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (bar, idx) => idx
              .map((_) => TouchedSpotIndicatorData(
                    FlLine(color: AppColors.textMuted, strokeWidth: 1, dashArray: [3, 3]),
                    FlDotData(getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(radius: 5, color: color, strokeColor: Colors.white, strokeWidth: 2)),
                  ))
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceHigh,
            // tooltipRoundedRadius: 10,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (spots) => spots.map((s) {
              final p = points[s.spotIndex];
              return LineTooltipItem(
                '${Fmt.price(p.price)}\n',
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                children: [
                  TextSpan(
                    text: DateFormat('d MMM, HH:mm').format(p.time),
                    style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].price)],
            isCurved: true,
            curveSmoothness: 0.15,
            barWidth: 2.2,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
