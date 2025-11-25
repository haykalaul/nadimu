import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/controllers/onboarding_controller.dart';
import 'package:nadimu/views/widgets/onboarding_page.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final onboarding = controller.currentOnboarding;
        return OnboardingPage(
          lottieAsset: 'assets/lottie/onboarding${controller.currentPage.value + 1}.json',
          title: onboarding.title,
          description: onboarding.description,
          onNext: controller.nextPage,
          onSkip: controller.skip,
          isLast: controller.currentPage.value == controller.onboardingPages.length - 1,
        );
      }),
    );
  }
}