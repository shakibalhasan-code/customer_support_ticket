import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:workflowx/core/config/api_endpoints.dart';
import 'package:workflowx/core/config/app_constants.dart';
import 'package:workflowx/core/helper/pref_helper.dart';
import 'package:workflowx/core/routes/app_pages.dart'; // Make sure these routes exist
import 'package:workflowx/core/services/api_services.dart';

class AuthController extends GetxController {
  /// Controllers for authentication
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpPinController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPassContoller = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var agreeToPrivacyPolicy = false.obs;

  /// Stores email for password reset flow
  var emailForPasswordReset = ''.obs;

  /// OTP resend countdown timer
  var otpResendSeconds = 60.obs;
  Timer? _otpResendTimer;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    confirmPassContoller.dispose();
    fullNameController.dispose();

    super.onClose();
  }

  Future<void> createAccount() async {
    try {
      isLoading.value = true;
      final body = {
        "email": emailController.text.trim(),
        "fullName": fullNameController.text.trim(),
        "password": passwordController.text.trim(),
      };

      final response = await ApiServices.postOnly(
        url: ApiEndpoints.register,
        body: body,
      );

      if (response.statusCode == 200) {
        // After registration, navigate to OTP verification screen
        Get.offAllNamed(Routes.forgotPasswordVerify);
      } else {
        final responseData = jsonDecode(response.body);
        Get.snackbar(
          'Registration Failed',
          responseData['message'] ?? 'Could not create account.',
        );
      }
    } catch (e) {
      printError(info: 'Error during account creation: $e');
      Get.snackbar('Error', 'An error occurred during account creation.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginAccount() async {
    try {
      isLoading.value = true;
      final body = {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      };
      final response = await ApiServices.postOnly(
        url: ApiEndpoints.login,
        body: body,
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['data']['accessToken'] ?? '';
        if (token.isEmpty) {
          Get.snackbar('Error', 'Failed to retrieve access token.');
          isLoading.value = false;
          return;
        }
        await PrefHelper.setString(AppConstants.token, token);
        Get.offAllNamed(Routes.home);
      } else {
        final responseData = jsonDecode(response.body);
        Get.snackbar(
          'Login Failed',
          responseData['message'] ?? 'Invalid credentials.',
        );
      }
    } catch (e) {
      printError(info: 'Error during login: $e');
      Get.snackbar('Error', 'An error occurred during login.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    try {
      isLoading.value = true;

      final otpValue = otpPinController.text.trim();
      if (otpValue.length != 4) {
        Get.snackbar('Invalid OTP', 'Please enter the 4-digit code.');
        isLoading.value = false;
        return;
      }

      // Pick email for OTP verification
      final emailToVerify =
          emailForPasswordReset.value.isNotEmpty
              ? emailForPasswordReset.value
              : emailController.text.trim();

      if (emailToVerify.isEmpty) {
        Get.snackbar('Error', 'Email not found for OTP verification.');
        isLoading.value = false;
        return;
      }

      final body = {'email': emailToVerify, 'otp': otpValue};

      final response = await ApiServices.patchOnly(
        url: ApiEndpoints.verifyUser,
        body: body,
      );

      if (response.statusCode == 200) {
        otpPinController.clear();

        if (emailForPasswordReset.value.isNotEmpty) {
          Get.offAllNamed(Routes.createNewPassword);
        } else {
          Get.offAllNamed(Routes.home);
        }
      } else {
        final responseData = jsonDecode(response.body);
        Get.snackbar(
          'OTP Verification Failed',
          responseData['message'] ?? 'Please check the code and try again.',
        );
      }
    } catch (e) {
      printError(info: 'Error during OTP verification: $e');
      Get.snackbar('Error', 'An error occurred while verifying OTP.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (otpResendSeconds.value != 0 || isLoading.value) return;

    try {
      isLoading.value = true;

      final emailToResend =
          emailForPasswordReset.value.isNotEmpty
              ? emailForPasswordReset.value
              : emailController.text.trim();

      if (emailToResend.isEmpty) {
        Get.snackbar('Error', 'Email not found for resending OTP.');
        isLoading.value = false;
        return;
      }

      final body = {'email': emailToResend};

      final response = await ApiServices.patchOnly(
        url: ApiEndpoints.forgotPass,
        body: body,
      );

      if (response.statusCode == 200) {
        otpResendSeconds.value = 60;
        _startOtpResendTimer();
        Get.snackbar('OTP Sent', 'A new OTP has been sent to your email.');
      } else {
        final responseData = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          responseData['message'] ?? 'Failed to resend OTP.',
        );
      }
    } catch (e) {
      printError(info: 'Error during OTP resend: $e');
      Get.snackbar('Error', 'An error occurred while resending OTP.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPass() async {
    try {
      isLoading.value = true;
      if (newPasswordController.text.trim() !=
          confirmPassContoller.text.trim()) {
        Get.snackbar('Error', 'Passwords do not match.');
        isLoading.value = false;
        return;
      }
      if (emailForPasswordReset.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Session expired or email not found. Please try password reset again.',
        );
        isLoading.value = false;
        Get.offAllNamed(Routes.signIn);
        return;
      }

      final body = {
        'new_password': newPasswordController.text.trim(),
        'confirm_password': confirmPassContoller.text.trim(),
      };

      final response = await ApiServices.patch(
        url: ApiEndpoints.resetPass,
        body: body,
      );
      if (response.statusCode == 200) {
        Get.offAllNamed(Routes.signIn);
        Get.snackbar(
          'Success',
          'Password has been reset successfully. Please login.',
        );
      } else {
        final responseData = jsonDecode(response.body);
        Get.snackbar(
          'Password Reset Failed',
          responseData['message'] ?? 'Could not reset password.',
        );
      }
    } catch (e) {
      printError(info: 'Error during password reset: $e');
      Get.snackbar('Error', 'An error occurred during password reset.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgot() async {
    try {
      isLoading.value = true;
      final email = emailController.text.trim();
      if (email.isEmpty) {
        Get.snackbar('Error', 'Please enter your email address.');
        isLoading.value = false;
        return;
      }
      final body = {'email': email};
      final response = await ApiServices.patchOnly(
        url: ApiEndpoints.forgotPass,
        body: body,
      );
      if (response.statusCode == 200) {
        emailForPasswordReset.value = email;
        Get.toNamed(Routes.forgotPasswordVerify);
        onOtpScreenInit();
      } else {
        final responseData = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          responseData['message'] ?? 'Failed to initiate password reset.',
        );
      }
    } catch (e) {
      printError(info: 'Error during forgot password: $e');
      Get.snackbar('Error', 'An error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _startOtpResendTimer() {
    _otpResendTimer?.cancel();
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpResendSeconds.value == 0) {
        timer.cancel();
      } else {
        otpResendSeconds.value--;
      }
    });
  }

  void onOtpScreenInit() {
    otpPinController.clear();
    otpResendSeconds.value = 60;
    _startOtpResendTimer();
  }

  void toggleAgreeToPrivacyPolicy() {
    agreeToPrivacyPolicy.value = !agreeToPrivacyPolicy.value;
  }
}
