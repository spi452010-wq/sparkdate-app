import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../data/onboarding_page.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final index = 0.obs;

  bool get isLast => index.value == onboardingPages.length - 1;

  void onPageChanged(int i) => index.value = i;

  void next() {
    if (isLast) {
      finish();
    } else {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void finish() => Get.offAllNamed(Routes.login);

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
