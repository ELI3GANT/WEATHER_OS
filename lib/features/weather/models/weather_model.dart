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
    this.utcOffsetSeconds = 0,
    this.wmoCode,
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
  final int utcOffsetSeconds;
  final int? wmoCode;

  /// The Open-Meteo offset belongs to the forecast location. An explicitly
  /// supplied time is already a location-local test/preview value.
  DateTime locationNow({DateTime? now}) =>
      now ?? DateTime.now().toUtc().add(Duration(seconds: utcOffsetSeconds));

  DateTime locationTimeFromUtc(DateTime utcTime) =>
      utcTime.toUtc().add(Duration(seconds: utcOffsetSeconds));

  static bool isCompleteCachePayload(Map<String, dynamic> json) {
    const numberFields = <String>[
      'temperature',
      'feelsLike',
      'high',
      'low',
      'humidity',
      'windSpeedMph',
      'uvIndex',
      'pressureInHg',
      'precipChance',
      'totalRainInches',
      'visibilityMiles',
      'windBearingDegrees',
      'utcOffsetSeconds',
    ];
    if (json['location'] is! String || json['condition'] is! String) {
      return false;
    }
    for (final field in numberFields) {
      final value = json[field];
      if (value is! num || !value.isFinite) return false;
    }
    final hourly = json['hourly'];
    final daily = json['dailyForecasts'];
    if (hourly is! List || hourly.isEmpty || daily is! List || daily.isEmpty) {
      return false;
    }
    return hourly.every((item) => _isValidHourlyCacheItem(item)) &&
        daily.every((item) => _isValidDailyCacheItem(item));
  }

  static bool _isValidHourlyCacheItem(dynamic item) {
    if (item is! Map<String, dynamic> ||
        item['timeLabel'] is! String ||
        item['condition'] is! String ||
        item['threatLevel'] is! String ||
        item['isNow'] is! bool) {
      return false;
    }
    for (final field in <String>['temperature', 'precipChance']) {
      final value = item[field];
      if (value is! num || !value.isFinite) return false;
    }
    return true;
  }

  static bool _isValidDailyCacheItem(dynamic item) {
    if (item is! Map<String, dynamic> ||
        item['dayLabel'] is! String ||
        item['condition'] is! String) {
      return false;
    }
    for (final field in <String>[
      'high',
      'low',
      'precipChance',
      'uvIndex',
      'totalRainInches',
    ]) {
      final value = item[field];
      if (value is! num || !value.isFinite) return false;
    }
    return true;
  }

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
    final currentUnits =
        (json['current_units'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final dailyUnits =
        (json['daily_units'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final hourlyUnits =
        (json['hourly_units'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    final utcOffsetSeconds = (json['utc_offset_seconds'] as num?)?.toInt();
    if (utcOffsetSeconds == null) {
      throw const FormatException(
        'Weather response is missing its location timezone offset.',
      );
    }

    final temperatureValue = (current['temperature_2m'] as num?)?.toDouble();
    if (temperatureValue == null || !temperatureValue.isFinite) {
      throw const FormatException(
        'Weather response is missing current temperature.',
      );
    }
    final temp = _temperatureF(
      temperatureValue,
      currentUnits['temperature_2m'] as String?,
    );
    final rawFeelsLike = (current['apparent_temperature'] as num?)?.toDouble();
    final feelsLike = rawFeelsLike == null
        ? null
        : _temperatureF(
            rawFeelsLike,
            currentUnits['apparent_temperature'] as String?,
          );
    final weatherCode = (current['weather_code'] as num?)?.toInt();
    final humidity = (current['relative_humidity_2m'] as num?)?.round();
    final rawWindSpeed = (current['wind_speed_10m'] as num?)?.toDouble();
    final windSpeed = rawWindSpeed == null
        ? null
        : _windMph(rawWindSpeed, currentUnits['wind_speed_10m'] as String?);
    final windDirection = (current['wind_direction_10m'] as num?)?.toDouble();
    final visibility = (current['visibility'] as num?)?.toDouble();
    final currentTime = DateTime.tryParse(current['time'] as String? ?? '');

    if (feelsLike == null ||
        !feelsLike.isFinite ||
        weatherCode == null ||
        humidity == null ||
        windSpeed == null ||
        !windSpeed.isFinite ||
        windDirection == null ||
        !windDirection.isFinite ||
        visibility == null ||
        !visibility.isFinite ||
        currentTime == null) {
      throw const FormatException(
        'Weather response is missing required current conditions.',
      );
    }

    final rawPressure = (current['surface_pressure'] as num?)?.toDouble();
    if (rawPressure == null || !rawPressure.isFinite) {
      throw const FormatException(
        'Weather response is missing surface pressure.',
      );
    }
    // Open-Meteo returns hPa by default (1 hPa ≈ 0.02953 inHg). Convert if > 100.
    final pressureInHg = _pressureInHg(
      rawPressure,
      currentUnits['surface_pressure'] as String?,
    );

    final dailyMaxList = (daily['temperature_2m_max'] as List<dynamic>?)
        ?.cast<num>();
    final dailyMinList = (daily['temperature_2m_min'] as List<dynamic>?)
        ?.cast<num>();
    final dailyUvList = (daily['uv_index_max'] as List<dynamic>?)?.cast<num>();
    final dailyRainList = (daily['precipitation_sum'] as List<dynamic>?)
        ?.cast<num>();
    final dailyPrecipProbList =
        (daily['precipitation_probability_max'] as List<dynamic>?)?.cast<num>();
    final dailySunriseList = (daily['sunrise'] as List<dynamic>?)
        ?.cast<String>();
    final dailySunsetList = (daily['sunset'] as List<dynamic>?)?.cast<String>();

    if (dailyMaxList == null ||
        dailyMaxList.isEmpty ||
        !dailyMaxList.first.toDouble().isFinite ||
        dailyMinList == null ||
        dailyMinList.isEmpty ||
        !dailyMinList.first.toDouble().isFinite) {
      throw const FormatException(
        'Weather response is missing daily temperatures.',
      );
    }

    final high = _temperatureF(
      dailyMaxList.first.toDouble(),
      dailyUnits['temperature_2m_max'] as String?,
    );
    final low = _temperatureF(
      dailyMinList.first.toDouble(),
      dailyUnits['temperature_2m_min'] as String?,
    );
    if (dailyUvList == null ||
        dailyUvList.isEmpty ||
        dailyRainList == null ||
        dailyRainList.isEmpty ||
        dailyPrecipProbList == null ||
        dailyPrecipProbList.isEmpty ||
        dailySunriseList == null ||
        dailySunriseList.isEmpty ||
        dailySunsetList == null ||
        dailySunsetList.isEmpty) {
      throw const FormatException(
        'Weather response is missing required daily data.',
      );
    }
    final uvIndex = dailyUvList.first.round();
    // Open-Meteo is queried with `precipitation_unit=inch`, so these values
    // are already inches. Converting again under-reports rainfall by ~25×.
    final rawDailyRain = dailyRainList.first.toDouble();
    if (!rawDailyRain.isFinite) {
      throw const FormatException(
        'Weather response has invalid precipitation.',
      );
    }
    final totalRain = _precipitationInches(
      rawDailyRain,
      dailyUnits['precipitation_sum'] as String?,
    );
    final precipProb = dailyPrecipProbList.first.round().clamp(0, 100);

    String? sunriseStr;
    String? sunsetStr;
    DateTime? parsedSunrise;
    DateTime? parsedSunset;
    final sunrise = DateTime.tryParse(dailySunriseList.first);
    if (sunrise != null) {
      parsedSunrise = sunrise;
      sunriseStr = _formatTime(sunrise.hour, sunrise.minute);
    }
    final sunset = DateTime.tryParse(dailySunsetList.first);
    if (sunset != null) {
      parsedSunset = sunset;
      sunsetStr = _formatTime(sunset.hour, sunset.minute);
    }
    if (sunriseStr == null || sunsetStr == null) {
      throw const FormatException(
        'Weather response has invalid solar timestamps.',
      );
    }

    final diff = parsedSunset!.difference(parsedSunrise!);
    if (diff.isNegative || diff.inMinutes <= 0) {
      throw const FormatException(
        'Weather response has invalid daylight duration.',
      );
    }
    final computedDaylight =
        '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';

    final hourlyTimes =
        (hourly['time'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final hourlyTemps =
        (hourly['temperature_2m'] as List<dynamic>?)?.cast<num>() ?? <num>[];
    final hourlyCodes =
        (hourly['weather_code'] as List<dynamic>?)?.cast<num>() ?? <num>[];
    final hourlyPrecipProbs =
        (hourly['precipitation_probability'] as List<dynamic>?)?.cast<num>() ??
        <num>[];

    if (hourlyTimes.isEmpty ||
        hourlyTimes.length != hourlyTemps.length ||
        hourlyTimes.length != hourlyCodes.length ||
        hourlyTimes.length != hourlyPrecipProbs.length) {
      throw const FormatException(
        'Weather response has incomplete hourly forecast data.',
      );
    }

    // With `timezone=auto`, Open-Meteo timestamps are local wall-clock times
    // for the forecast location. Anchor selection to `current.time` rather
    // than this device's timezone so searched cities do not skip hours.
    final now = currentTime;
    if (!hourlyTemps.every((value) => value.isFinite) ||
        !hourlyCodes.every((value) => value.isFinite) ||
        !hourlyPrecipProbs.every((value) => value.isFinite) ||
        !hourlyTimes.every((value) => DateTime.tryParse(value) != null)) {
      throw const FormatException(
        'Weather response has invalid hourly forecast data.',
      );
    }

    final hourlyList = <HourlyForecast>[];
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
      final hTemp = _temperatureF(
        hourlyTemps[idx].toDouble(),
        hourlyUnits['temperature_2m'] as String?,
      );
      final hCode = hourlyCodes[idx].toInt();
      final hPrecipProb = hourlyPrecipProbs[idx].round().clamp(0, 100);

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
      WeatherCondition.rain => 'Rain is currently reported for this location.',
      WeatherCondition.storm =>
        'Thunderstorms are currently reported for this location.',
      WeatherCondition.snow => 'Snow is currently reported for this location.',
      WeatherCondition.fog => 'Dense fog reducing visibility on roadways.',
      WeatherCondition.cloudy =>
        weatherCode == 3
            ? 'Overcast skies are currently reported for this location.'
            : 'Partly cloudy skies are currently reported for this location.',
      WeatherCondition.sunny =>
        'Clear skies are currently reported for this location.',
    };

    final risk = (cond == WeatherCondition.storm)
        ? 'HIGH RISK'
        : (cond == WeatherCondition.rain ? 'MODERATE RISK' : 'LOW RISK');

    final dailyTimes = (daily['time'] as List<dynamic>?)?.cast<String>();
    final dailyWeatherCodes =
        (daily['weather_code'] as List<dynamic>?)?.cast<num>() ?? <num>[];

    if (dailyTimes == null ||
        dailyTimes.isEmpty ||
        dailyTimes.length != dailyMaxList.length ||
        dailyTimes.length != dailyMinList.length ||
        dailyTimes.length != dailyWeatherCodes.length ||
        dailyTimes.length != dailyUvList.length ||
        dailyTimes.length != dailyRainList.length ||
        dailyTimes.length != dailyPrecipProbList.length ||
        dailyTimes.length != dailySunriseList.length ||
        dailyTimes.length != dailySunsetList.length) {
      throw const FormatException(
        'Weather response has incomplete daily forecast data.',
      );
    }
    if (!dailyMaxList.every((value) => value.isFinite) ||
        !dailyMinList.every((value) => value.isFinite) ||
        !dailyUvList.every((value) => value.isFinite) ||
        !dailyRainList.every((value) => value.isFinite) ||
        !dailyPrecipProbList.every((value) => value.isFinite) ||
        !dailyWeatherCodes.every((value) => value.isFinite) ||
        !dailyTimes.every((value) => DateTime.tryParse(value) != null) ||
        !dailySunriseList.every((value) => DateTime.tryParse(value) != null) ||
        !dailySunsetList.every((value) => DateTime.tryParse(value) != null)) {
      throw const FormatException(
        'Weather response has invalid daily forecast data.',
      );
    }

    final dailyList = <DailyForecastItem>[];
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    {
      final count = dailyMaxList.length;
      for (var i = 0; i < count && i < 7; i++) {
        final dDate = DateTime.tryParse(dailyTimes[i]);
        if (dDate == null) {
          throw const FormatException(
            'Weather response has invalid daily dates.',
          );
        }

        final dayLabel = i == 0
            ? 'Today'
            : (i == 1 ? 'Tomorrow' : weekdayNames[dDate.weekday - 1]);

        final dHigh = _temperatureF(
          dailyMaxList[i].toDouble(),
          dailyUnits['temperature_2m_max'] as String?,
        );
        final dLow = _temperatureF(
          dailyMinList[i].toDouble(),
          dailyUnits['temperature_2m_min'] as String?,
        );
        final dCode = dailyWeatherCodes[i].toInt();
        final dCondition = WeatherCondition.fromWmoCode(dCode);
        final dPrecip = dailyPrecipProbList[i].round().clamp(0, 100);
        final dUv = dailyUvList[i].round();
        final dRain = _precipitationInches(
          dailyRainList[i].toDouble(),
          dailyUnits['precipitation_sum'] as String?,
        );
        final dSunrise = _formatDateTimeString(dailySunriseList[i]);
        final dSunset = _formatDateTimeString(dailySunsetList[i]);

        dailyList.add(
          DailyForecastItem(
            dayLabel: dayLabel,
            date: dDate,
            condition: dCondition,
            high: dHigh,
            low: dLow,
            precipChance: dPrecip,
            uvIndex: dUv,
            totalRainInches:
                double.tryParse(
                  dRain.isFinite ? dRain.toStringAsFixed(2) : '0.0',
                ) ??
                0.0,
            sunrise: dSunrise,
            sunset: dSunset,
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
      pressureInHg: double.tryParse(pressureInHg.toStringAsFixed(2)) ?? 30.0,
      precipChance: precipProb,
      totalRainInches: double.tryParse(totalRain.toStringAsFixed(2)) ?? 0.0,
      // Open-Meteo's visibility unit follows its response configuration. The
      // imperial forecast request currently returns feet, while older and
      // mocked payloads can use metres. Read `current_units` rather than
      // assuming a unit and overstating visibility by 3.28x.
      visibilityMiles: _visibilityMiles(
        visibility,
        (json['current_units'] as Map<String, dynamic>?)?['visibility']
            as String?,
      ),
      windDirectionCompass: _degreesToCompass(windDirection),
      windBearingDegrees: windDirection,
      sunriseTime: sunriseStr,
      sunsetTime: sunsetStr,
      daylightDuration: computedDaylight,
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
        if (cond == WeatherCondition.storm) 'Thunderstorms possible',
        if (cond == WeatherCondition.snow) 'Winter road conditions',
        if (cond == WeatherCondition.fog) 'Reduced visibility possible',
        if (cond == WeatherCondition.sunny || cond == WeatherCondition.cloudy)
          'No significant precipitation currently reported',
      ],
      impactScores: <String, int>{
        'Driving': cond == WeatherCondition.rain ? 80 : 25,
        'Outdoor Plans': cond == WeatherCondition.rain ? 30 : 85,
        'Construction': 35,
        'Running': cond == WeatherCondition.rain ? 20 : 90,
        'Flying Drones': cond == WeatherCondition.rain ? 15 : 85,
        'Photography': 25,
      },
      utcOffsetSeconds: utcOffsetSeconds,
      wmoCode: weatherCode,
      hourly: hourlyList,
      dailyForecasts: dailyList,
    );
  }

  static double _visibilityMiles(double visibility, String? unit) {
    final value = visibility;
    return switch (unit) {
      'ft' => value / 5280,
      'm' || null => value / 1609.344,
      _ => value / 1609.344,
    };
  }

  static double _temperatureF(double value, String? unit) => switch (unit) {
    '°C' || 'C' => (value * 9 / 5) + 32,
    _ => value,
  };

  static double _windMph(double value, String? unit) => switch (unit) {
    'km/h' => value * 0.621371,
    'm/s' => value * 2.23694,
    _ => value,
  };

  static double _precipitationInches(double value, String? unit) =>
      switch (unit) {
        'mm' => value / 25.4,
        _ => value,
      };

  static double _pressureInHg(double value, String? unit) => switch (unit) {
    'hPa' || 'mbar' || null => value * 0.02953,
    _ => value,
  };

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
    'utcOffsetSeconds': utcOffsetSeconds,
    'wmoCode': wmoCode,
    'hourly': hourly.map((HourlyForecast h) => h.toJson()).toList(),
    'dailyForecasts': dailyForecasts
        .map((DailyForecastItem d) => d.toJson())
        .toList(),
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
    totalRainInches: (json['totalRainInches'] as num?)?.toDouble() ?? 0.80,
    visibilityMiles: (json['visibilityMiles'] as num?)?.toDouble() ?? 8.0,
    windDirectionCompass: json['windDirectionCompass'] as String? ?? 'ESE',
    windBearingDegrees:
        (json['windBearingDegrees'] as num?)?.toDouble() ?? 112.0,
    sunriseTime: json['sunriseTime'] as String? ?? '5:36 AM',
    sunsetTime: json['sunsetTime'] as String? ?? '8:08 PM',
    daylightDuration: json['daylightDuration'] as String? ?? '14h 32m',
    dailySummary:
        json['dailySummary'] as String? ??
        'Rainy with a high chance of showers and thunderstorms.',
    riskLevel: json['riskLevel'] as String? ?? 'LOW RISK',
    severeRisks:
        (json['severeRisks'] as Map<String, dynamic>?)?.map(
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
    whatToExpect:
        (json['whatToExpect'] as List<dynamic>?)?.cast<String>() ??
        const <String>[
          'Bring an umbrella',
          'Slick roads possible',
          'Thunderstorms this afternoon',
          'Heavy rain around midday',
          'Plan for delays',
        ],
    impactScores:
        (json['impactScores'] as Map<String, dynamic>?)?.map(
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
    utcOffsetSeconds: (json['utcOffsetSeconds'] as num?)?.toInt() ?? 0,
    wmoCode: (json['wmoCode'] as num?)?.toInt(),
    hourly: ((json['hourly'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
        .toList(),
    dailyForecasts: ((json['dailyForecasts'] as List<dynamic>?) ?? <dynamic>[])
        .map(
          (dynamic e) => DailyForecastItem.fromJson(e as Map<String, dynamic>),
        )
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
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final normalized = (degrees % 360 + 360) % 360;
    final index = ((normalized + 11.25) / 22.5).floor() % directions.length;
    return directions[index];
  }
}
