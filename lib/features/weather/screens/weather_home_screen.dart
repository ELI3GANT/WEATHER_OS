import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_condition.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../providers/weather_scope.dart';
import '../widgets/current_conditions_hero.dart';
import '../widgets/daily_forecast_view.dart';
import '../widgets/hourly_forecast_rail.dart';
import '../widgets/radar_view.dart';
import '../widgets/weather_alerts_view.dart';
import '../widgets/weather_atmosphere.dart';
import '../widgets/weather_bottom_nav_bar.dart';
import '../widgets/weather_celestial_compass_card.dart';
import '../widgets/weather_charts_card.dart';
import '../widgets/weather_impact_meter_card.dart';
import '../widgets/weather_metric_card_grid.dart';
import '../widgets/weather_severe_risk_matrix.dart';
import '../widgets/weather_status_view.dart';
import '../widgets/weather_weekly_outlook_card.dart';

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  int _selectedForecastIndex = 0;
  WeatherNavTab _currentTab = WeatherNavTab.today;

  void _onForecastSelected(int index) {
    setState(() {
      _selectedForecastIndex = index;
    });
  }

  void _onTabSelected(WeatherNavTab tab) {
    setState(() {
      _currentTab = tab;
    });
  }

  int? _parseHourFromLabel(String label) {
    if (label == 'NOW') {
      return DateTime.now().hour;
    }
    final parts = label.split(' ');
    if (parts.length >= 2) {
      final hourNum = int.tryParse(parts[0]);
      final isPm = parts[1].toUpperCase() == 'PM';
      if (hourNum != null) {
        if (isPm && hourNum < 12) {
          return hourNum + 12;
        } else if (!isPm && hourNum == 12) {
          return 0;
        }
        return hourNum;
      }
    }
    return null;
  }

  String _formatTodayHeaderDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Today • ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = WeatherScope.watch(context);
    final weather = provider.weather;

    WeatherCondition activeCondition = WeatherCondition.cloudy;
    int? activeHour;

    if (weather != null) {
      if (_selectedForecastIndex > 0 &&
          _selectedForecastIndex < weather.hourly.length) {
        final forecast = weather.hourly[_selectedForecastIndex];
        activeCondition = forecast.condition;
        activeHour = _parseHourFromLabel(forecast.timeLabel);
      } else {
        activeCondition = weather.condition;
        activeHour = DateTime.now().hour;
      }
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: WeatherAtmosphere(
              condition: activeCondition,
              customHour: activeHour,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                // Top Header Bar
                if (weather != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WeatherSpacing.space4,
                      vertical: WeatherSpacing.space2,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: WeatherPalette.mistBlue,
                        ),
                        const SizedBox(width: WeatherSpacing.space1),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              weather.location,
                              style: WeatherType.title.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: WeatherPalette.textPrimary,
                              ),
                            ),
                            Text(
                              _formatTodayHeaderDate(),
                              style: WeatherType.label.copyWith(
                                fontSize: 11,
                                color: WeatherPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: WeatherPalette.textPrimary,
                          ),
                          onPressed: () => WeatherScope.read(context).refresh(),
                          tooltip: 'Refresh Weather',
                        ),
                      ],
                    ),
                  ),

                // Main Tab Content
                Expanded(
                  child: RepaintBoundary(
                    key: const ValueKey<String>('weather-content-boundary'),
                    child: _WeatherTabBody(
                      provider: provider,
                      currentTab: _currentTab,
                      selectedForecastIndex: _selectedForecastIndex,
                      onForecastSelected: _onForecastSelected,
                    ),
                  ),
                ),

                // Bottom Optical Glass Navigation Bar
                if (provider.state == WeatherLoadState.loaded)
                  WeatherBottomNavBar(
                    currentTab: _currentTab,
                    onTabSelected: _onTabSelected,
                    alertCount: (weather != null && weather.riskLevel == 'HIGH RISK')
                        ? 2
                        : ((weather != null &&
                                (weather.riskLevel == 'MODERATE RISK' ||
                                    weather.condition == WeatherCondition.storm ||
                                    weather.condition == WeatherCondition.rain))
                            ? 1
                            : 0),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherTabBody extends StatelessWidget {
  const _WeatherTabBody({
    required this.provider,
    required this.currentTab,
    required this.selectedForecastIndex,
    required this.onForecastSelected,
  });

  final WeatherProvider provider;
  final WeatherNavTab currentTab;
  final int selectedForecastIndex;
  final ValueChanged<int> onForecastSelected;

  @override
  Widget build(BuildContext context) {
    return switch (provider.state) {
      WeatherLoadState.initial ||
      WeatherLoadState.loading => const WeatherLoadingView(),
      WeatherLoadState.loaded => AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: switch (currentTab) {
            WeatherNavTab.today => _TodayDashboardView(
                key: const ValueKey('tab_today'),
                weather: provider.weather!,
                selectedForecastIndex: selectedForecastIndex,
                onForecastSelected: onForecastSelected,
              ),
            WeatherNavTab.hourly => _HourlyTabDetailView(
                key: const ValueKey('tab_hourly'),
                weather: provider.weather!,
                selectedForecastIndex: selectedForecastIndex,
                onForecastSelected: onForecastSelected,
              ),
            WeatherNavTab.daily => DailyForecastView(
                key: const ValueKey('tab_daily'),
                weather: provider.weather!,
              ),
            WeatherNavTab.radar => const RadarView(
                key: ValueKey('tab_radar'),
              ),
            WeatherNavTab.alerts => WeatherAlertsView(
                key: const ValueKey('tab_alerts'),
                weather: provider.weather,
              ),
          },
        ),
      WeatherLoadState.error => WeatherErrorView(
          message: provider.errorMessage!,
          onRetry: provider.load,
        ),
    };
  }
}

class _TodayDashboardView extends StatelessWidget {
  const _TodayDashboardView({
    required this.weather,
    required this.selectedForecastIndex,
    required this.onForecastSelected,
    super.key,
  });

  final WeatherModel weather;
  final int selectedForecastIndex;
  final ValueChanged<int> onForecastSelected;

  WeatherModel _buildDisplayWeather() {
    if (selectedForecastIndex > 0 &&
        selectedForecastIndex < weather.hourly.length) {
      final forecast = weather.hourly[selectedForecastIndex];
      return WeatherModel(
        location: weather.location,
        temperature: forecast.temperature,
        condition: forecast.condition,
        feelsLike: forecast.temperature,
        high: weather.high,
        low: weather.low,
        humidity: weather.humidity,
        windSpeedMph: weather.windSpeedMph,
        uvIndex: weather.uvIndex,
        pressureInHg: weather.pressureInHg,
        precipChance: forecast.precipChance,
        totalRainInches: weather.totalRainInches,
        visibilityMiles: weather.visibilityMiles,
        windDirectionCompass: weather.windDirectionCompass,
        windBearingDegrees: weather.windBearingDegrees,
        sunriseTime: weather.sunriseTime,
        sunsetTime: weather.sunsetTime,
        daylightDuration: weather.daylightDuration,
        dailySummary: weather.dailySummary,
        riskLevel: weather.riskLevel,
        severeRisks: weather.severeRisks,
        whatToExpect: weather.whatToExpect,
        impactScores: weather.impactScores,
        hourly: weather.hourly,
      );
    }
    return weather;
  }

  @override
  Widget build(BuildContext context) {
    final displayWeather = _buildDisplayWeather();

    return RefreshIndicator(
      color: WeatherPalette.mistBlue,
      backgroundColor: WeatherPalette.lensCore,
      onRefresh: () => WeatherScope.read(context).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: WeatherSpacing.space4,
          vertical: WeatherSpacing.space2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Hero Telemetry & Summary
            CurrentConditionsHero(weather: displayWeather),
            const SizedBox(height: WeatherSpacing.space3),

            // 2. Hourly Forecast Rail & Threat Intensity Bar
            HourlyForecastRail(
              forecasts: weather.hourly,
              selectedIndex: selectedForecastIndex,
              onForecastSelected: onForecastSelected,
            ),
            const SizedBox(height: WeatherSpacing.space3),

            // 3. 7-Day Weekly Forecast Outlook
            WeatherWeeklyOutlookCard(weather: weather),
            const SizedBox(height: WeatherSpacing.space3),

            // 4. Hex-Metric Glass Grid (Precip, Total Rain, Humidity, Wind, Vis, UV)
            WeatherMetricCardGrid(weather: displayWeather),
            const SizedBox(height: WeatherSpacing.space3),

            // 4. Severe Weather Risk Matrix (Rain, Thunder, Flood, Wind, Hail, Tornado)
            WeatherSevereRiskMatrix(weather: displayWeather),
            const SizedBox(height: WeatherSpacing.space3),

            // 5. Dual Interactive Vector Charts (Temp curve + Precip bar chart)
            WeatherChartsCard(
              weather: weather,
              selectedIndex: selectedForecastIndex,
            ),
            const SizedBox(height: WeatherSpacing.space3),

            // 6. Celestial & Activity Intelligence (Sun timeline + Wind compass)
            WeatherCelestialCompassCard(weather: displayWeather),
            const SizedBox(height: WeatherSpacing.space3),

            // 7. Impact Meter & What to Expect
            WeatherImpactMeterCard(weather: displayWeather),
            const SizedBox(height: WeatherSpacing.space6),
          ],
        ),
      ),
    );
  }
}

class _HourlyTabDetailView extends StatelessWidget {
  const _HourlyTabDetailView({
    required this.weather,
    required this.selectedForecastIndex,
    required this.onForecastSelected,
    super.key,
  });

  final WeatherModel weather;
  final int selectedForecastIndex;
  final ValueChanged<int> onForecastSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          HourlyForecastRail(
            forecasts: weather.hourly,
            selectedIndex: selectedForecastIndex,
            onForecastSelected: onForecastSelected,
          ),
          const SizedBox(height: WeatherSpacing.space4),
          WeatherChartsCard(
            weather: weather,
            selectedIndex: selectedForecastIndex,
          ),
          const SizedBox(height: WeatherSpacing.space4),
          WeatherMetricCardGrid(weather: weather),
        ],
      ),
    );
  }
}
