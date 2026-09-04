import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/weather_model.dart';

/// Service responsible for exporting real-time weather telemetry to:
/// 1. Apple Watch (via WCSession / WatchConnectivity)
/// 2. iOS WidgetKit Home Screen / Lock Screen Widgets (via App Group UserDefaults)
class WatchExportService {
  static const MethodChannel _channel = MethodChannel(
    'tech.onlytrueperspective.weatheros/watch_sync',
  );

  static const String appGroupId = 'group.tech.onlytrueperspective.weatheros';

  /// Serializes and exports current WeatherModel to watchOS and WidgetKit.
  static Future<void> exportTelemetry(WeatherModel weather) async {
    // This can run from a provider's unawaited refresh callback. Ensure the
    // messenger exists before the optional platform channel is touched.
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final payload = <String, dynamic>{
        'location': weather.location,
        'temperature': weather.temperature,
        'feelsLike': weather.feelsLike,
        'condition': weather.condition.name,
        'high': weather.high,
        'low': weather.low,
        'precipChance': weather.precipChance,
        'totalRainInches': weather.totalRainInches,
        'windSpeedMph': weather.windSpeedMph,
        'uvIndex': weather.uvIndex,
        'riskLevel': weather.riskLevel,
        'dailySummary': weather.dailySummary,
        'sunrise': weather.sunriseTime,
        'sunset': weather.sunsetTime,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        // First 6 hours for Watch hourly rail
        'hourly': weather.hourly
            .take(6)
            .map(
              (h) => <String, dynamic>{
                'time': h.timeLabel,
                'temp': h.temperature.round(),
                'condition': h.condition.name,
                'precip': h.precipChance,
              },
            )
            .toList(),
        // 7-day outlook for watch face spectrum
        'daily': weather.dailyForecasts
            .map(
              (d) => <String, dynamic>{
                'day': d.dayLabel,
                'low': d.low.round(),
                'high': d.high.round(),
                'condition': d.condition.name,
                'precip': d.precipChance,
              },
            )
            .toList(),
      };

      final jsonString = jsonEncode(payload);

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _channel.invokeMethod('updateWatchAndWidgets', <String, dynamic>{
          'jsonPayload': jsonString,
          'appGroup': appGroupId,
        });
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Refresh Android home-screen widgets immediately after the app cache
        // is written; the OS periodic update can otherwise lag by 30 minutes.
        await _channel.invokeMethod('updateAndroidWidget');
      }

      debugPrint(
        '[WatchExportService] Successfully exported telemetry payload.',
      );
    } catch (e) {
      // Non-fatal if watch is not paired or channel is pending native link
      debugPrint('[WatchExportService] Export notice: $e');
    }
  }

  /// Prompts the Android OS to pin the WeatherOS widget to the home screen.
  static Future<bool> pinAndroidWidget() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('pinAndroidWidget');
      return result ?? false;
    } catch (e) {
      debugPrint('[WatchExportService] pinAndroidWidget notice: $e');
      return false;
    }
  }
}
