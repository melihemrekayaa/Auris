import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_info_service.dart';

// Provider for our service so it can be injected anywhere
final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

// A StateNotifier to manage the user's trial state
class TrialStateNotifier extends StateNotifier<AsyncValue<bool>> {
  final DeviceInfoService _service;

  TrialStateNotifier(this._service) : super(const AsyncValue.loading()) {
    checkTrialStatus();
  }

  Future<void> checkTrialStatus() async {
    try {
      state = const AsyncValue.loading();
      final hasUsed = await _service.hasUsedFreeTrial();
      state = AsyncValue.data(hasUsed);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> useTrial() async {
    try {
      await _service.markFreeTrialAsUsed();
      // Update state to reflect trial is used
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// The main provider the UI will watch
final trialProvider = StateNotifierProvider<TrialStateNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(deviceInfoServiceProvider);
  return TrialStateNotifier(service);
});
