import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController({this.duration = const Duration(seconds: 2)});
  final Duration duration;
  Timer? _t;

  @override
  void onReady() {
    super.onReady();
    _t = Timer(duration, () => Get.offAllNamed(Routes.onboarding));
  }

  @override
  void onClose() {
    _t?.cancel();
    super.onClose();
  }
}
