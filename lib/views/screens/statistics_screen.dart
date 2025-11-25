import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/controllers/statistics_controller.dart';
import 'package:nadimu/themes/app_theme.dart';
import 'package:nadimu/views/widgets/line_chart_widget.dart';

class StatisticsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const StatisticsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    // Get or create controller safely
    // When accessed via route, binding will lazyPut the controller
    // When accessed directly from HomeScreen, we need to create it
    // Try to find existing controller first (from lazyPut or previous put)
    StatisticsController controller;
    try {
      controller = Get.find<StatisticsController>();
    } catch (e) {
      // Controller not found, create it
      // Use put instead of putIfAbsent to avoid conflicts with lazyPut
      controller = Get.put(StatisticsController(), permanent: false);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E)),
                      onPressed: () {
                        if (onBack != null) {
                          onBack!();
                        } else if (Get.key.currentState?.canPop() ?? false) {
                          Get.back();
                        }
                      },
                    ),
                  ),
                  const Text(
                    'Health History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF1C1C1E)),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Obx(() => Row(
                            children: [
                              _buildFilterChip(
                                context,
                                label: 'Daily',
                                selected: controller.filter.value == 'Daily',
                                onTap: () => controller.changeFilter('Daily'),
                              ),
                              const SizedBox(width: 12),
                              _buildFilterChip(
                                context,
                                label: 'Weekly',
                                selected: controller.filter.value == 'Weekly',
                                onTap: () => controller.changeFilter('Weekly'),
                              ),
                              const SizedBox(width: 12),
                              _buildFilterChip(
                                context,
                                label: '7 Days',
                                selected: controller.filter.value == '7 Days',
                                onTap: () => controller.changeFilter('7 Days'),
                                showIcon: true,
                              ),
                            ],
                          )),
                    ),
                    // Period Summary Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: const Text(
                        'Period Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                    // Stats Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() {
                        // Ensure controller values are ready
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              context,
                              label: 'Avg Heart Rate',
                              value: '${controller.avgHeartRate.value}',
                              unit: 'BPM',
                            ),
                            _buildStatCard(
                              context,
                              label: 'Avg SpO2',
                              value: '${controller.avgSpo2.value}',
                              unit: '%',
                            ),
                            _buildStatCard(
                              context,
                              label: 'Highest Reading',
                              value: '${controller.highest.value}',
                              unit: 'BPM',
                            ),
                            _buildStatCard(
                              context,
                              label: 'Lowest Reading',
                              value: '${controller.lowest.value}',
                              unit: 'BPM',
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    // Charts
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Obx(() {
                            final heartRateList = controller.heartRateData.toList();
                            return _buildChartCard(
                              context,
                              title: 'Heart Rate (BPM)',
                              value: '85',
                              period: 'Today',
                              change: '+5.2%',
                              changeColor: AppTheme.green,
                              chartData: heartRateList,
                            );
                          }),
                          const SizedBox(height: 24),
                          Obx(() {
                            final spo2List = controller.spo2Data.toList();
                            return _buildChartCard(
                              context,
                              title: 'Oxygen Saturation (SpO2 %)',
                              value: '97',
                              period: 'Today',
                              change: '-1.1%',
                              changeColor: Colors.red,
                              chartData: spo2List,
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Health Patterns Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Patterns',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.trending_up,
                                    color: AppTheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Morning Stability',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1C1C1E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your heart rate was most stable in the morning between 7 AM and 10 AM.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool showIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.only(left: 16, right: showIcon ? 8 : 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF8E8E93),
              ),
            ),
            if (showIcon) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 20,
                color: selected ? Colors.white : const Color(0xFF8E8E93),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: value),
                const TextSpan(
                  text: ' ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required String value,
    required String period,
    required String change,
    required Color changeColor,
    required List<double> chartData,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                period,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                change.startsWith('+') ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: changeColor,
              ),
              Text(
                change,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: changeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 148,
            child: LineChartWidget(data: chartData),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text(
                '6am',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '9am',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '12pm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '3pm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '6pm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '9pm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}