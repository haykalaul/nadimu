import 'package:flutter/material.dart';
import 'package:nadimu/themes/app_theme.dart';
import 'package:nadimu/views/screens/analysis_screen.dart';
import 'package:nadimu/views/screens/dashboard_screen.dart';
import 'package:nadimu/views/screens/history_screen.dart';
import 'package:nadimu/views/screens/statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      StatisticsScreen(onBack: _handleStatisticsBack),
      const HistoryScreen(),
      const AnalysisScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark.withOpacity(0.8) : AppTheme.cardLight.withOpacity(0.8),
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: 'Dashboard',
                index: 0,
                isDark: isDark,
              ),
              _buildNavItem(
                context,
                icon: Icons.bar_chart,
                label: 'Statistics',
                index: 1,
                isDark: isDark,
              ),
              _buildNavItem(
                context,
                icon: Icons.history,
                label: 'History',
                index: 2,
                isDark: isDark,
              ),
              _buildNavItem(
                context,
                icon: Icons.psychology,
                label: 'Analysis',
                index: 3,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppTheme.primary
                  : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStatisticsBack() {
    setState(() => _selectedIndex = 0);
  }
}