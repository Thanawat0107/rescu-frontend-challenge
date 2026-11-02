import 'dart:async';

import 'package:get/get.dart';

/// [F-1] Central heartbeat service: ticks every 1 second for the whole app.
/// This avoids running multiple timers in individual cards, saving battery and CPU.
class CountdownService extends GetxService {
  // Observable current time. Updates every 1 second.
  final now = DateTime.now().obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();

    // Start a single periodic timer (1 tick per second)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    // Cancel the timer when service is disposed to prevent leaks
    _timer?.cancel();
    super.onClose();
  }
}
