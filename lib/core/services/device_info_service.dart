import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Gets a unique ID for the device (IdentifierForVendor on iOS, AndroidId on Android).
  Future<String?> getUniqueDeviceId() async {
    try {
      if (Platform.isIOS) {
        var iosDeviceInfo = await _deviceInfo.iosInfo;
        return iosDeviceInfo.identifierForVendor; 
      } else if (Platform.isAndroid) {
        var androidDeviceInfo = await _deviceInfo.androidInfo;
        // In modern Android versions, androidId is unique per app signing key
        return androidDeviceInfo.id; 
      }
    } catch (e) {
      print("Failed to get device info: \$e");
    }
    return null;
  }

  /// Checks if the device has already used the free trial
  Future<bool> hasUsedFreeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_used_free_trial') ?? false;
  }

  /// Marks the free trial as used for this device
  Future<void> markFreeTrialAsUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_used_free_trial', true);
  }
}
