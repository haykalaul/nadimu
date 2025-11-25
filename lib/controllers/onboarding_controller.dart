import 'package:get/get.dart';
import 'package:nadimu/routes/app_routes.dart';

class OnboardingData {
  final String title;
  final String description;

  OnboardingData({
    required this.title,
    required this.description,
  });
}

class OnboardingController extends GetxController {
  var currentPage = 0.obs;

  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      title: 'Welcome to Nadimu',
      description: 'Monitor your heart rate and oxygen saturation in real-time with our advanced health monitoring system.',
    ),
    OnboardingData(
      title: 'Track Your Health',
      description: 'Get detailed insights and analysis of your cardiovascular health with AI-powered recommendations.',
    ),
    OnboardingData(
      title: 'Stay Connected',
      description: 'Connect your health monitoring device via Bluetooth or WiFi and start tracking your wellness journey.',
    ),
  ];

  OnboardingData get currentOnboarding => onboardingPages[currentPage.value];

  void nextPage() {
    if (currentPage.value < onboardingPages.length - 1) {
      currentPage.value++;
    } else {
      Get.offNamed(AppRoutes.login); // Ke auth setelah onboarding
    }
  }

  void skip() {
    Get.offNamed(AppRoutes.login);
  }
}