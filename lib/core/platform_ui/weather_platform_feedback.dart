import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'weather_native_contracts.dart';
import 'weather_native_ui_bridge.dart';
import 'weather_platform.dart';

abstract final class WeatherPlatformFeedback {
  static void selection([BuildContext? context]) {
    if (WeatherPlatform.isIOS(context)) {
      if (WeatherNativeUIBridge.instance.isNativeBridgeAvailable) {
        WeatherNativeUIBridge.instance.triggerHaptic(HapticType.selection);
      } else {
        HapticFeedback.selectionClick();
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void impact([BuildContext? context]) {
    if (WeatherPlatform.isIOS(context)) {
      if (WeatherNativeUIBridge.instance.isNativeBridgeAvailable) {
        WeatherNativeUIBridge.instance.triggerHaptic(HapticType.medium);
      } else {
        HapticFeedback.mediumImpact();
      }
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void light([BuildContext? context]) {
    if (WeatherPlatform.isIOS(context)) {
      if (WeatherNativeUIBridge.instance.isNativeBridgeAvailable) {
        WeatherNativeUIBridge.instance.triggerHaptic(HapticType.light);
      } else {
        HapticFeedback.lightImpact();
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void heavy([BuildContext? context]) {
    if (WeatherPlatform.isIOS(context)) {
      if (WeatherNativeUIBridge.instance.isNativeBridgeAvailable) {
        WeatherNativeUIBridge.instance.triggerHaptic(HapticType.heavy);
      } else {
        HapticFeedback.heavyImpact();
      }
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}
