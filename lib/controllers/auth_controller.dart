import 'package:get/get.dart';
import 'package:nadimu/routes/app_routes.dart';

class AuthController extends GetxController {
  // Simulasi login/register karena UI saja
  void login() {
    Get.offAllNamed(AppRoutes.home);
  }

  void register() {
    Get.offAllNamed(AppRoutes.home);
  }

  void skipAuth() {
    Get.offAllNamed(AppRoutes.home);
  }
}