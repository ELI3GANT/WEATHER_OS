import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class WeatherPlatform {
  static TargetPlatform? _overridePlatform;

  @visibleForTesting
  static TargetPlatform? get overridePlatform => _overridePlatform;

  @visibleForTesting
  static set overridePlatform(TargetPlatform? platform) {
    _overridePlatform = platform;
  }

  @visibleForTesting
  static void setOverridePlatform(TargetPlatform? platform) {
    _overridePlatform = platform;
  }

  static TargetPlatform of(BuildContext? context) {
    if (_overridePlatform != null) return _overridePlatform!;
    if (context != null) {
      return Theme.of(context).platform;
    }
    return defaultTargetPlatform;
  }

  static bool isIOS([BuildContext? context]) {
    final platform = of(context);
    return platform == TargetPlatform.iOS;
  }

  static bool isAndroid([BuildContext? context]) {
    return of(context) == TargetPlatform.android;
  }
}
