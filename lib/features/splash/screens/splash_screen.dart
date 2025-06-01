import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:workflowx/features/splash/controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});
  final contrller = Get.put(SplashController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CupertinoActivityIndicator()));
  }
}
