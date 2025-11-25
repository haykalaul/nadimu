import 'package:get/get.dart';
import 'package:nadimu/routes/app_routes.dart';

class AccountController extends GetxController {
  var username = 'John Doe'.obs;
  var email = 'john.doe@example.com'.obs;
  var phoneNumber = '+62 812 3456 7890'.obs;
  var dateOfBirth = '15 January 1990'.obs;
  var gender = 'Male'.obs;
  var height = '175 cm'.obs;
  var weight = '70 kg'.obs;

  void logout() {
    Get.offAllNamed(AppRoutes.login);
  }

  void updateProfile() {
    // Profile update logic here
    // Snackbar will be shown from UI
  }

  void changeGender(String newGender) {
    gender.value = newGender;
  }
}