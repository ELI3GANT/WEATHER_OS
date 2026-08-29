import 'weather_condition.dart';
import 'weather_model.dart';

enum WeatherConditionFamily {
  clear,
  cloudy,
  rain,
  storm,
  snow,
  fog,
  wind,
}

enum DaylightPhase { night, dawn, day, sunset }

class WeatherAtmosphereState {
  const WeatherAtmosphereState({
    required this.conditionFamily,
    required this.daylightPhase,
    required this.cloudIntensity,
    required this.precipitationIntensity,
    required this.windIntensity,
    required this.windDirection,
    required this.visibilityFactor,
    required this.temperatureCharacter,
    required this.severeIntensity,
    required this.isOvercast,
    required this.isHeavyPrecipitation,
    required this.storyLine,
  });

  final WeatherConditionFamily conditionFamily;
  final DaylightPhase daylightPhase;
  final double cloudIntensity;
  final double precipitationIntensity;
  final double windIntensity;
  final double windDirection;
  final double visibilityFactor;
  final double temperatureCharacter;
  final double severeIntensity;
  final bool isOvercast;
  final bool isHeavyPrecipitation;
  final String storyLine;

  static WeatherAtmosphereState fromWeather(
    WeatherModel weather, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final daylightPhase = _resolveDaylightPhase(
      currentTime,
      sunriseTime: weather.sunriseTime,
      sunsetTime: weather.sunsetTime,
    );

    final isOvercast = weather.condition == WeatherCondition.cloudy &&
        (weather.humidity >= 60 ||
            weather.uvIndex <= 3 ||
            weather.dailySummary.toLowerCase().contains('overcast'));

    final isHeavyPrecipitation = (weather.condition == WeatherCondition.rain ||
            weather.condition == WeatherCondition.storm) &&
        (weather.totalRainInches >= 0.35 ||
            weather.precipChance >= 75 ||
            (weather.impactScores['Weather'] ?? 0) >= 3 ||
            weather.dailySummary.toLowerCase().contains('heavy'));

    final isHighWind = weather.windSpeedMph >= 20.0 &&
        (weather.condition == WeatherCondition.sunny ||
            weather.condition == WeatherCondition.cloudy);

    final conditionFamily = isHighWind
        ? WeatherConditionFamily.wind
        : switch (weather.condition) {
            WeatherCondition.sunny => WeatherConditionFamily.clear,
            WeatherCondition.cloudy => WeatherConditionFamily.cloudy,
            WeatherCondition.rain => WeatherConditionFamily.rain,
            WeatherCondition.storm => WeatherConditionFamily.storm,
            WeatherCondition.snow => WeatherConditionFamily.snow,
            WeatherCondition.fog => WeatherConditionFamily.fog,
          };

    final cloudIntensity = switch (conditionFamily) {
      WeatherConditionFamily.clear => 0.15,
      WeatherConditionFamily.cloudy => isOvercast ? 0.85 : 0.45,
      WeatherConditionFamily.rain => isHeavyPrecipitation ? 0.95 : 0.75,
      WeatherConditionFamily.storm => 1.0,
      WeatherConditionFamily.snow => 0.70,
      WeatherConditionFamily.fog => 0.90,
      WeatherConditionFamily.wind => 0.50,
    };

    final precipitationIntensity = switch (conditionFamily) {
      WeatherConditionFamily.rain => isHeavyPrecipitation
          ? (weather.precipChance / 100.0).clamp(0.65, 1.0)
          : (weather.precipChance / 100.0).clamp(0.15, 0.75),
      WeatherConditionFamily.storm =>
        (weather.precipChance / 100.0).clamp(0.70, 1.0),
      WeatherConditionFamily.snow =>
        (weather.precipChance / 100.0).clamp(0.20, 1.0),
      _ => 0.0,
    };

    final windIntensity = (weather.windSpeedMph / 35.0).clamp(0.0, 1.0);
    final visibilityFactor = (weather.visibilityMiles / 10.0).clamp(0.0, 1.0);
    final temperatureCharacter =
        ((weather.temperature - 50.0) / 40.0).clamp(-1.0, 1.0);

    final severeBase = weather.severeRisks.isEmpty
        ? 0.0
        : weather.severeRisks.values
                .fold<double>(0.0, (sum, value) => sum + value) /
            weather.severeRisks.length;
    final riskLevelBoost = switch (weather.riskLevel.toUpperCase()) {
      'HIGH RISK' => 0.8,
      'MODERATE RISK' => 0.4,
      _ => 0.0,
    };
    final severeIntensity =
        severeBase > 0 ? severeBase : riskLevelBoost.clamp(0.0, 1.0);

    final storyLine = _buildStoryLine(
      conditionFamily: conditionFamily,
      daylightPhase: daylightPhase,
      isOvercast: isOvercast,
      isHeavyPrecipitation: isHeavyPrecipitation,
      precipChance: weather.precipChance,
      windSpeedMph: weather.windSpeedMph,
      temperature: weather.temperature,
    );

    return WeatherAtmosphereState(
      conditionFamily: conditionFamily,
      daylightPhase: daylightPhase,
      cloudIntensity: cloudIntensity,
      precipitationIntensity: precipitationIntensity,
      windIntensity: windIntensity,
      windDirection: weather.windBearingDegrees,
      visibilityFactor: visibilityFactor,
      temperatureCharacter: temperatureCharacter,
      severeIntensity: severeIntensity,
      isOvercast: isOvercast,
      isHeavyPrecipitation: isHeavyPrecipitation,
      storyLine: storyLine,
    );
  }

  static DaylightPhase _resolveDaylightPhase(
    DateTime now, {
    String? sunriseTime,
    String? sunsetTime,
  }) {
    final sunriseMinutes = _parseTimeOfDayMinutes(sunriseTime);
    final sunsetMinutes = _parseTimeOfDayMinutes(sunsetTime);

    if (sunriseMinutes != null && sunsetMinutes != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      const transitionWindowMinutes = 45;

      final dawnStart = sunriseMinutes - transitionWindowMinutes;
      final dawnEnd = sunriseMinutes + transitionWindowMinutes;
      final duskStart = sunsetMinutes - transitionWindowMinutes;
      final duskEnd = sunsetMinutes + transitionWindowMinutes;

      if (nowMinutes >= dawnStart && nowMinutes < dawnEnd) {
        return DaylightPhase.dawn;
      } else if (nowMinutes >= dawnEnd && nowMinutes < duskStart) {
        return DaylightPhase.day;
      } else if (nowMinutes >= duskStart && nowMinutes < duskEnd) {
        return DaylightPhase.sunset;
      } else {
        return DaylightPhase.night;
      }
    }

    final hour = now.hour;
    if (hour >= 5 && hour < 7) return DaylightPhase.dawn;
    if (hour >= 7 && hour < 18) return DaylightPhase.day;
    if (hour >= 18 && hour < 21) return DaylightPhase.sunset;
    return DaylightPhase.night;
  }

  static int? _parseTimeOfDayMinutes(String? timeString) {
    if (timeString == null || timeString.trim().isEmpty) return null;
    final clean = timeString.trim().toUpperCase();

    // Supports "6:15 AM", "12:30 PM", "18:45", "6:15"
    final isPm = clean.contains('PM');
    final isAm = clean.contains('AM');
    final digits = clean.replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = digits.split(':');
    if (parts.isEmpty) return null;

    var hour = int.tryParse(parts[0]);
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (hour == null) return null;

    if (isPm && hour < 12) {
      hour += 12;
    } else if (isAm && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }

  static String _buildStoryLine({
    required WeatherConditionFamily conditionFamily,
    required DaylightPhase daylightPhase,
    required bool isOvercast,
    required bool isHeavyPrecipitation,
    required int precipChance,
    required double windSpeedMph,
    required double temperature,
  }) {
    final tempFeel = temperature >= 75
        ? 'warm'
        : (temperature <= 40 ? 'crisp cold' : 'mild');

    return switch (conditionFamily) {
      WeatherConditionFamily.clear => switch (daylightPhase) {
          DaylightPhase.night =>
            'Clear night skies with star visibility and a $tempFeel atmosphere.',
          DaylightPhase.dawn =>
            'Dawn light breaking over clear skies with a fresh $tempFeel feel.',
          DaylightPhase.sunset =>
            'Golden hour sunset with radiant horizons and steady conditions.',
          DaylightPhase.day =>
            'Luminous clear skies with open sunshine and a $tempFeel atmosphere.',
        },
      WeatherConditionFamily.cloudy => isOvercast
          ? 'Overcast cloud cover filtering solar radiance with cool, steady air.'
          : 'Partly cloudy skies with bright sun breaks and layered cloud motion.',
      WeatherConditionFamily.rain => isHeavyPrecipitation
          ? 'Heavy steady rainfall with lowered visibility and saturated air.'
          : 'Light rain passing through with damp atmospheric mist.',
      WeatherConditionFamily.storm =>
        'Severe thunderstorm activity with heavy precipitation, lightning risk, and gusty winds.',
      WeatherConditionFamily.snow =>
        'Active snowfall with cold crisp air and layered winter diffusion.',
      WeatherConditionFamily.fog =>
        'Dense fog bank softening horizon lines and reducing visibility.',
      WeatherConditionFamily.wind => windSpeedMph >= 18
          ? 'High atmospheric winds shaping rapid cloud drift and strong air currents.'
          : 'Breezy conditions keeping the atmosphere moving throughout the day.',
    };
  }
}
