import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nadimu/themes/app_theme.dart';

class LineChartWidget extends StatelessWidget {
  final List<double> data;
  final Color? lineColor;

  const LineChartWidget({
    super.key,
    required this.data,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 120);
    }

    final color = lineColor ?? AppTheme.primary;
    final minY = data.reduce((a, b) => a < b ? a : b) - 10;
    final maxY = data.reduce((a, b) => a > b ? a : b) + 10;

    // Use parent height if available, otherwise default to 120
    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.maxHeight > 0 ? constraints.maxHeight : 120.0;
        return SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}