import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () => Get.offNamed(AppRoutes.onboarding));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Nadimu',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }
}