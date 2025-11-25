import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/themes/app_theme.dart';
import 'package:nadimu/views/widgets/line_chart_widget.dart';

class HistoryDetailsScreen extends StatelessWidget {
  const HistoryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map<String, dynamic>?) ?? {};
    final dateLabel = args['date']?.toString() ?? 'Health Session';
    final timeLabel = args['time']?.toString() ?? '10:30 AM';
    final avgHeartRate = args['avgHeartRate'] ?? 72;
    final avgSpo2 = args['avgSpo2'] ?? 98;
    final duration = args['duration'] ?? 15;
    final activity = args['activity']?.toString() ?? 'Resting';
    final insights = args['insights']?.toString() ?? 'Stable heart rate with minor fluctuations.';
    final notes = args['notes']?.toString() ?? 'Felt a bit dizzy after standing up.';

    final heartRateData =
        (args['heartRateData'] as List<double>?) ?? List<double>.generate(16, (i) => 70 + (i % 4) * 2 + (i.isEven ? 2 : -1));
    final spo2Data =
        (args['spo2Data'] as List<double>?) ?? List<double>.generate(16, (i) => 95 + (i % 3));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, dateLabel, timeLabel, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(avgHeartRate, avgSpo2, duration, isDark),
                    const SizedBox(height: 16),
                    _buildActivityChip(activity, isDark),
                    const SizedBox(height: 16),
                    _MetricChartCard(
                      title: 'Heart Rate (BPM)',
                      value: avgHeartRate.toString(),
                      subtitle: 'Per Minute',
                      chartData: heartRateData,
                    ),
                    const SizedBox(height: 16),
                    _MetricChartCard(
                      title: 'Blood Oxygen (SpO₂ %)',
                      value: avgSpo2.toString(),
                      subtitle: 'Per Minute',
                      chartData: spo2Data,
                    ),
                    const SizedBox(height: 16),
                    _InsightCard(
                      title: 'Gemini AI Insights',
                      subtitle: 'Stable Heart Rate with Minor Fluctuations',
                      content: insights,
                      icon: Icons.auto_awesome,
                    ),
                    const SizedBox(height: 16),
                    _NotesCard(
                      content: notes,
                      onEdit: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String date, String time, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight).withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF333333)),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  date,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.ios_share, color: isDark ? Colors.white : const Color(0xFF333333)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int avgHeartRate, int avgSpo2, int duration, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;
        return Wrap(
          runSpacing: 12,
          spacing: 12,
          children: [
            _StatsCard(
              label: 'Avg Heart Rate',
              value: avgHeartRate.toString(),
              unit: 'BPM',
              isDark: isDark,
              width: isWide ? (constraints.maxWidth - 12) / 3 : (constraints.maxWidth - 12) / 2,
            ),
            _StatsCard(
              label: 'Avg SpO₂',
              value: avgSpo2.toString(),
              unit: '%',
              isDark: isDark,
              width: isWide ? (constraints.maxWidth - 12) / 3 : (constraints.maxWidth - 12) / 2,
            ),
            _StatsCard(
              label: 'Duration',
              value: duration.toString(),
              unit: 'min',
              isDark: isDark,
              width: isWide ? (constraints.maxWidth - 12) / 3 : constraints.maxWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityChip(String activity, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(isDark ? 0.3 : 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        activity,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.red[200] : AppTheme.primary,
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isDark;
  final double width;

  const _StatsCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF333333),
                ),
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChartCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final List<double> chartData;

  const _MetricChartCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChartWidget(data: chartData),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              Text('5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              Text('10', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              Text('15', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String content;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String content;
  final VoidCallback onEdit;

  const _NotesCard({
    required this.content,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'My Notes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text('Edit', style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}