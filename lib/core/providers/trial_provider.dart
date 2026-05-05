import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_info_service.dart';

// Provider for our service so it can be injected anywhere
final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

// An AsyncNotifier to manage the user's trial state (Modern Riverpod 3.x syntax)
class TrialNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Watch the service
    final service = ref.watch(deviceInfoServiceProvider);
    // Fetch the initial state
    return await service.hasUsedFreeTrial();
  }

  Future<void> useTrial() async {
    try {
      final service = ref.read(deviceInfoServiceProvider);
      await service.markFreeTrialAsUsed();
      // Update state to reflect trial is used
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// The main provider the UI will watch
final trialProvider = AsyncNotifierProvider<TrialNotifier, bool>(() {
  return TrialNotifier();
});
