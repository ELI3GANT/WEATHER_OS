import 'daily_forecast_item.dart';
import 'hourly_forecast.dart';
import 'weather_condition.dart';

class WeatherModel {
  const WeatherModel({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.feelsLike,
    required this.high,
    required this.low,
    required this.humidity,
    required this.windSpeedMph,
    required this.uvIndex,
    required this.pressureInHg,
    required this.hourly,
    this.dailyForecasts = const <DailyForecastItem>[],
    this.precipChance = 90,
    this.totalRainInches = 0.80,
    this.visibilityMiles = 8.0,
    this.windDirectionCompass = 'ESE',
    this.windBearingDegrees = 112.0,
    this.sunriseTime = '5:36 AM',
    this.sunsetTime = '8:08 PM',
    this.daylightDuration = '14h 32m',
    this.dailySummary =
        'Rainy with a high chance of showers and thunderstorms.',
    this.riskLevel = 'LOW RISK',
    this.severeRisks = const <String, double>{
      'rain': 0.85,
      'thunderstorms': 0.55,
      'flooding': 0.50,
      'wind': 0.25,
      'hail': 0.20,
      'tornado': 0.05,
    },
    this.whatToExpect = const <String>[
      'Bring an umbrella',
      'Slick roads possible',
      'Thunderstorms this afternoon',
      'Heavy rain around midday',
      'Plan for delays',
    ],
    this.impactScores = const <String, int>{
      'Driving': 80,
      'Outdoor Plans': 30,
      'Construction': 35,
      'Running': 20,
      'Flying Drones': 15,
      'Photography': 25,
    },
  });

  final String location;
  final double temperature;
  final WeatherCondition condition;
  final double feelsLike;
  final double high;
  final double low;
  final int humidity;
  final double windSpeedMph;
  final int uvIndex;
  final double pressureInHg;
  final List<HourlyForecast> hourly;
  final List<DailyForecastItem> dailyForecasts;
  final int precipChance;
  final double totalRainInches;
  final double visibilityMiles;
  final String windDirectionCompass;
  final double windBearingDegrees;
  final String sunriseTime;
  final String sunsetTime;
  final String daylightDuration;
  final String dailySummary;
  final String riskLevel;
  final Map<String, double> severeRisks;
  final List<String> whatToExpect;
  final Map<String, int> impactScores;

  /// Factory constructor to parse standard Open-Meteo API response.
  factory WeatherModel.fromOpenMeteoJson(
    Map<String, dynamic> json, {
    String location = 'New York',
  }) {
    final current =
        (json['current'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final daily =
        (json['daily'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final hourly =
        (json['hourly'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 70.0;
    final feelsLike =
        (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
    final weatherCode = (current['weather_code'] as num?)?.toInt();
    final humidity =
        (current['relative_humidity_2m'] as num?)?.round() ?? 50;
    final windSpeed =
        (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final windDirection =
        (current['wind_direction_10m'] as num?)?.toDouble() ?? 112.0;

    final rawPressure =
        (current['surface_pressure'] as num?)?.toDouble() ?? 1013.25;
    // Open-Meteo returns hPa by default (1 hPa ≈ 0.02953 inHg). Convert if > 100.
    final pressureInHg =
        rawPressure > 100 ? rawPressure * 0.02953 : rawPressure;

    final dailyMaxList =
        (daily['temperature_2m_max'] as List<dynamic>?)?.cast<num>();
    final dailyMinList =
        (daily['temperature_2m_min'] as List<dynamic>?)?.cast<num>();
    final dailyUvList =
        (daily['uv_index_max'] as List<dynamic>?)?.cast<num>();
    final dailyRainList =
        (daily['precipitation_sum'] as List<dynamic>?)?.cast<num>();
    final dailyPrecipProbList =
        (daily['precipitation_probability_max'] as List<dynamic>?)?.cast<num>();
    final dailySunriseList =
        (daily['sunrise'] as List<dynamic>?)?.cast<String>();
    final dailySunsetList =
        (daily['sunset'] as List<dynamic>?)?.cast<String>();

    final high = (dailyMaxList != null && dailyMaxList.isNotEmpty)
        ? dailyMaxList.first.toDouble()
        : temp + 4;
    final low = (dailyMinList != null && dailyMinList.isNotEmpty)
        ? dailyMinList.first.toDouble()
        : temp - 6;
    final uvIndex = (dailyUvList != null && dailyUvList.isNotEmpty)
        ? dailyUvList.first.round()
        : 3;
    final totalRain = (dailyRainList != null && dailyRainList.isNotEmpty)
        ? dailyRainList.first.toDouble() * 0.03937 // mm to inches
        : 0.80;
    final precipProb = (dailyPrecipProbList != null && dailyPrecipProbList.isNotEmpty)
        ? dailyPrecipProbList.first.round()
        : 90;

    var sunriseStr = '5:36 AM';
    var sunsetStr = '8:08 PM';
    if (dailySunriseList != null && dailySunriseList.isNotEmpty) {
      final s = DateTime.tryParse(dailySunriseList.first);
      if (s != null) {
        sunriseStr = _formatTime(s.hour, s.minute);
      }
    }
    if (dailySunsetList != null && dailySunsetList.isNotEmpty) {
      final s = DateTime.tryParse(dailySunsetList.first);
      if (s != null) {
        sunsetStr = _formatTime(s.hour, s.minute);
      }
    }

    final hourlyTimes =
        (hourly['time'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final hourlyTemps =
        (hourly['temperature_2m'] as List<dynamic>?)?.cast<num>() ?? <num>[];
    final hourlyCodes =
        (hourly['weather_code'] as List<dynamic>?)?.cast<num>() ?? <num>[];
    final hourlyPrecipProbs =
        (hourly['precipitation_probability'] as List<dynamic>?)?.cast<num>() ??
            <num>[];

    final hourlyList = <HourlyForecast>[];
    final now = DateTime.now();
    var startIndex = 0;
    for (var i = 0; i < hourlyTimes.length; i++) {
      final parsed = DateTime.tryParse(hourlyTimes[i]);
      if (parsed != null &&
          (parsed.isAfter(now) ||
              (parsed.year == now.year &&
                  parsed.month == now.month &&
                  parsed.day == now.day &&
                  parsed.hour == now.hour))) {
        startIndex = i;
        break;
      }
    }

    const maxItems = 24;
    const step = 1;
    for (var i = 0; i < maxItems; i++) {
      final idx = startIndex + (i * step);
      if (idx >= hourlyTimes.length) {
        break;
      }
      final timeStr = hourlyTimes[idx];
      final parsedTime = DateTime.tryParse(timeStr);
      final isNow = i == 0;
      final timeLabel = isNow
          ? 'NOW'
          : (parsedTime != null ? _formatHour(parsedTime.hour) : '+$i h');
      final hTemp =
          idx < hourlyTemps.length ? hourlyTemps[idx].toDouble() : temp;
      final hCode =
          idx < hourlyCodes.length ? hourlyCodes[idx].toInt() : weatherCode;
      final hPrecipProb = idx < hourlyPrecipProbs.length
          ? hourlyPrecipProbs[idx].round()
          : (precipProb > 50 ? 70 : 20);

      final threat = hPrecipProb > 75
          ? 'high'
          : (hPrecipProb > 35 ? 'moderate' : 'low');

      hourlyList.add(
        HourlyForecast(
          timeLabel: timeLabel,
          temperature: hTemp,
          condition: WeatherCondition.fromWmoCode(hCode),
          precipChance: hPrecipProb,
          threatLevel: threat,
          isNow: isNow,
        ),
      );
    }

    final cond = WeatherCondition.fromWmoCode(weatherCode);
    final summary = switch (cond) {
      WeatherCondition.rain =>
        'Rainy with a high chance of showers and precipitation.',
      WeatherCondition.storm =>
        'Severe storms and lightning expected this afternoon.',
      WeatherCondition.snow =>
        'Winter weather conditions with snowfall accumulation.',
      WeatherCondition.fog => 'Dense fog reducing visibility on roadways.',
      WeatherCondition.cloudy => 'Overcast skies with mild breezes.',
      WeatherCondition.sunny =>
        'Clear and comfortable conditions throughout the day.',
    };

    final risk = (cond == WeatherCondition.storm)
        ? 'HIGH RISK'
        : (cond == WeatherCondition.rain ? 'MODERATE RISK' : 'LOW RISK');

    final dailyTimes =
        (daily['time'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final dailyWeatherCodes =
        (daily['weather_code'] as List<dynamic>?)?.cast<num>() ?? <num>[];

    final dailyList = <DailyForecastItem>[];
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (dailyMaxList != null && dailyMaxList.isNotEmpty) {
      final count = dailyMaxList.length;
      for (var i = 0; i < count && i < 7; i++) {
        final dTimeStr = i < dailyTimes.length ? dailyTimes[i] : null;
        final dDate = dTimeStr != null
            ? DateTime.tryParse(dTimeStr)
            : DateTime.now().add(Duration(days: i));

        final dayLabel = i == 0
            ? 'Today'
            : (i == 1
                ? 'Tomorrow'
                : (dDate != null
                    ? weekdayNames[dDate.weekday - 1]
                    : 'Day $i'));

        final dHigh = dailyMaxList[i].toDouble();
        final dLow = (dailyMinList != null && i < dailyMinList.length)
            ? dailyMinList[i].toDouble()
            : dHigh - 12.0;
        final dCode = (dailyWeatherCodes.isNotEmpty &&
                i < dailyWeatherCodes.length)
            ? dailyWeatherCodes[i].toInt()
            : (i == 0 ? weatherCode : null);
        final dCondition = WeatherCondition.fromWmoCode(dCode);
        final dPrecip = (dailyPrecipProbList != null &&
                i < dailyPrecipProbList.length)
            ? dailyPrecipProbList[i].round()
            : (dCondition == WeatherCondition.rain
                ? 70
                : (dCondition == WeatherCondition.storm ? 85 : 10));
        final dUv = (dailyUvList != null && i < dailyUvList.length)
            ? dailyUvList[i].round()
            : uvIndex;
        final dRain = (dailyRainList != null && i < dailyRainList.length)
            ? dailyRainList[i].toDouble() * 0.03937
            : 0.0;
        final dSunrise = (dailySunriseList != null && i < dailySunriseList.length)
            ? _formatDateTimeString(dailySunriseList[i])
            : null;
        final dSunset = (dailySunsetList != null && i < dailySunsetList.length)
            ? _formatDateTimeString(dailySunsetList[i])
            : null;

        dailyList.add(
          DailyForecastItem(
            dayLabel: dayLabel,
            date: dDate,
            condition: dCondition,
            high: dHigh,
            low: dLow,
            precipChance: dPrecip,
            uvIndex: dUv,
            totalRainInches: double.parse(dRain.toStringAsFixed(2)),
            sunrise: dSunrise,
            sunset: dSunset,
          ),
        );
      }
    }

    if (dailyList.isEmpty) {
      final now = DateTime.now();
      for (var i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final label = i == 0
            ? 'Today'
            : (i == 1 ? 'Tomorrow' : weekdayNames[date.weekday - 1]);
        dailyList.add(
          DailyForecastItem(
            dayLabel: label,
            date: date,
            condition: i == 0
                ? cond
                : (i % 2 == 0
                    ? WeatherCondition.sunny
                    : WeatherCondition.cloudy),
            high: high + (i % 3 == 0 ? 2 : -2),
            low: low + (i % 2 == 0 ? 1 : -1),
            precipChance: i == 0 ? precipProb : (i * 10) % 40,
            uvIndex: uvIndex,
          ),
        );
      }
    }

    return WeatherModel(
      location: location,
      temperature: temp,
      condition: cond,
      feelsLike: feelsLike,
      high: high,
      low: low,
      humidity: humidity,
      windSpeedMph: windSpeed,
      uvIndex: uvIndex,
      pressureInHg: double.parse(pressureInHg.toStringAsFixed(2)),
      precipChance: precipProb,
      totalRainInches: double.parse(totalRain.toStringAsFixed(2)),
      visibilityMiles: 8.0,
      windDirectionCompass: _degreesToCompass(windDirection),
      windBearingDegrees: windDirection,
      sunriseTime: sunriseStr,
      sunsetTime: sunsetStr,
      daylightDuration: '14h 32m',
      dailySummary: summary,
      riskLevel: risk,
      severeRisks: <String, double>{
        'rain': cond == WeatherCondition.rain ? 0.85 : 0.15,
        'thunderstorms': cond == WeatherCondition.storm ? 0.90 : 0.20,
        'flooding': cond == WeatherCondition.rain ? 0.70 : 0.15,
        'wind': (windSpeed / 40.0).clamp(0.05, 0.95),
        'hail': cond == WeatherCondition.storm ? 0.40 : 0.05,
        'tornado': 0.05,
      },
      whatToExpect: <String>[
        if (cond == WeatherCondition.rain) 'Bring an umbrella',
        if (cond == WeatherCondition.rain) 'Slick roads possible',
        if (cond == WeatherCondition.storm) 'Thunderstorms this afternoon',
        if (cond == WeatherCondition.snow) 'Winter road conditions',
        'Plan for travel delays',
      ],
      impactScores: <String, int>{
        'Driving': cond == WeatherCondition.rain ? 80 : 25,
        'Outdoor Plans': cond == WeatherCondition.rain ? 30 : 85,
        'Construction': 35,
        'Running': cond == WeatherCondition.rain ? 20 : 90,
        'Flying Drones': cond == WeatherCondition.rain ? 15 : 85,
        'Photography': 25,
      },
      hourly: hourlyList.isNotEmpty
          ? hourlyList
          : <HourlyForecast>[
              HourlyForecast(
                timeLabel: 'NOW',
                temperature: temp,
                condition: cond,
                precipChance: precipProb,
                isNow: true,
              ),
            ],
      dailyForecasts: dailyList,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'location': location,
        'temperature': temperature,
        'condition': condition.name,
        'feelsLike': feelsLike,
        'high': high,
        'low': low,
        'humidity': humidity,
        'windSpeedMph': windSpeedMph,
        'uvIndex': uvIndex,
        'pressureInHg': pressureInHg,
        'precipChance': precipChance,
        'totalRainInches': totalRainInches,
        'visibilityMiles': visibilityMiles,
        'windDirectionCompass': windDirectionCompass,
        'windBearingDegrees': windBearingDegrees,
        'sunriseTime': sunriseTime,
        'sunsetTime': sunsetTime,
        'daylightDuration': daylightDuration,
        'dailySummary': dailySummary,
        'riskLevel': riskLevel,
        'severeRisks': severeRisks,
        'whatToExpect': whatToExpect,
        'impactScores': impactScores,
        'hourly': hourly.map((HourlyForecast h) => h.toJson()).toList(),
        'dailyForecasts':
            dailyForecasts.map((DailyForecastItem d) => d.toJson()).toList(),
      };

  factory WeatherModel.fromJson(Map<String, dynamic> json) => WeatherModel(
        location: json['location'] as String? ?? 'Current Location',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 70.0,
        condition: WeatherCondition.values.firstWhere(
          (WeatherCondition c) => c.name == json['condition'],
          orElse: () => WeatherCondition.cloudy,
        ),
        feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 70.0,
        high: (json['high'] as num?)?.toDouble() ?? 75.0,
        low: (json['low'] as num?)?.toDouble() ?? 60.0,
        humidity: (json['humidity'] as num?)?.round() ?? 50,
        windSpeedMph: (json['windSpeedMph'] as num?)?.toDouble() ?? 10.0,
        uvIndex: (json['uvIndex'] as num?)?.round() ?? 3,
        pressureInHg: (json['pressureInHg'] as num?)?.toDouble() ?? 30.0,
        precipChance: (json['precipChance'] as num?)?.round() ?? 90,
        totalRainInches:
            (json['totalRainInches'] as num?)?.toDouble() ?? 0.80,
        visibilityMiles:
            (json['visibilityMiles'] as num?)?.toDouble() ?? 8.0,
        windDirectionCompass:
            json['windDirectionCompass'] as String? ?? 'ESE',
        windBearingDegrees:
            (json['windBearingDegrees'] as num?)?.toDouble() ?? 112.0,
        sunriseTime: json['sunriseTime'] as String? ?? '5:36 AM',
        sunsetTime: json['sunsetTime'] as String? ?? '8:08 PM',
        daylightDuration: json['daylightDuration'] as String? ?? '14h 32m',
        dailySummary: json['dailySummary'] as String? ??
            'Rainy with a high chance of showers and thunderstorms.',
        riskLevel: json['riskLevel'] as String? ?? 'LOW RISK',
        severeRisks: (json['severeRisks'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            const <String, double>{
              'rain': 0.85,
              'thunderstorms': 0.55,
              'flooding': 0.50,
              'wind': 0.25,
              'hail': 0.20,
              'tornado': 0.05,
            },
        whatToExpect: (json['whatToExpect'] as List<dynamic>?)?.cast<String>() ??
            const <String>[
              'Bring an umbrella',
              'Slick roads possible',
              'Thunderstorms this afternoon',
              'Heavy rain around midday',
              'Plan for delays',
            ],
        impactScores: (json['impactScores'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).round()),
            ) ??
            const <String, int>{
              'Driving': 80,
              'Outdoor Plans': 30,
              'Construction': 35,
              'Running': 20,
              'Flying Drones': 15,
              'Photography': 25,
            },
        hourly: ((json['hourly'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyForecasts: ((json['dailyForecasts'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) =>
                DailyForecastItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static String? _formatDateTimeString(String? isoStr) {
    if (isoStr == null) return null;
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return null;
    return _formatTime(dt.hour, dt.minute);
  }

  static String _formatHour(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = (hour < 12 || hour == 24) ? 'AM' : 'PM';
    return '$h $ampm';
  }

  static String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = (hour < 12 || hour == 24) ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  static String _degreesToCompass(double degrees) {
    const directions = <String>[
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    final normalized = (degrees % 360 + 360) % 360;
    final index = ((normalized + 11.25) / 22.5).floor() % directions.length;
    return directions[index];
  }
}
