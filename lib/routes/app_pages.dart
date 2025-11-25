import 'package:get/get.dart';
import 'package:nadimu/controllers/account_controller.dart';
import 'package:nadimu/controllers/analysis_controller.dart';
import 'package:nadimu/controllers/auth_controller.dart';
import 'package:nadimu/controllers/connection_controller.dart';
import 'package:nadimu/controllers/dashboard_controller.dart';
import 'package:nadimu/controllers/history_controller.dart';
import 'package:nadimu/controllers/monitoring_controller.dart';
import 'package:nadimu/controllers/onboarding_controller.dart';
import 'package:nadimu/controllers/statistics_controller.dart';
import 'package:nadimu/routes/app_routes.dart';
import 'package:nadimu/views/screens/account_screen.dart';
import 'package:nadimu/views/screens/analysis_screen.dart';
import 'package:nadimu/views/screens/dashboard_screen.dart';
import 'package:nadimu/views/screens/history_details_screen.dart';
import 'package:nadimu/views/screens/history_screen.dart';
import 'package:nadimu/views/screens/home_screen.dart';
import 'package:nadimu/views/screens/iot_connection_screen.dart';
import 'package:nadimu/views/screens/login_screen.dart';
import 'package:nadimu/views/screens/onboarding_screen.dart';
import 'package:nadimu/views/screens/realtime_monitoring_screen.dart';
import 'package:nadimu/views/screens/register_screen.dart';
import 'package:nadimu/views/screens/splash_screen.dart';
import 'package:nadimu/views/screens/statistics_screen.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<OnboardingController>(() => OnboardingController())),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<AuthController>(() => AuthController())),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<AuthController>(() => AuthController())),
    ),
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<DashboardController>(() => DashboardController())),
    ),
    GetPage(
      name: AppRoutes.statistics,
      page: () => const StatisticsScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<StatisticsController>(() => StatisticsController())),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<HistoryController>(() => HistoryController())),
    ),
    GetPage(
      name: AppRoutes.historyDetails,
      page: () => const HistoryDetailsScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<HistoryController>(() => HistoryController())),
    ),
    GetPage(
      name: AppRoutes.analysis,
      page: () => const AnalysisScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<AnalysisController>(() => AnalysisController())),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<AccountController>(() => AccountController())),
    ),
    GetPage(
      name: AppRoutes.iotConnection,
      page: () => const IotConnectionScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<ConnectionController>(() => ConnectionController())),
    ),
    GetPage(
      name: AppRoutes.realtimeMonitoring,
      page: () => const RealtimeMonitoringScreen(),
      binding: BindingsBuilder(() => Get.lazyPut<MonitoringController>(() => MonitoringController())),
    ),
  ];
}