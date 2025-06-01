import 'package:get/get.dart';
import 'package:workflowx/core/config/app_constants.dart';
import 'package:workflowx/core/helper/pref_helper.dart';
import 'package:workflowx/core/routes/app_pages.dart' show Routes;

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initializeUser();
  }

  Future<void> initializeUser() async {
    try {
      final token = await PrefHelper.getString(AppConstants.token);
      if (token != null && token.isNotEmpty) {
        // User is logged in, navigate to home
        Get.offAllNamed(Routes.home);
      } else {
        // User is not logged in, navigate to sign-in screen
        Get.offAllNamed(Routes.signIn);
      }
    } catch (e) {
      // Handle any errors that occur during initialization
      print("Error during splash initialization: $e");
    }
  }
}
