import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_native_contracts.dart';
import '../../../core/platform_ui/weather_native_ui_bridge.dart';
import '../../../core/platform_ui/weather_platform.dart';
import '../../../core/platform_ui/weather_platform_header.dart';
import '../../../core/platform_ui/weather_platform_navigation_bar.dart';
import '../../../core/platform_ui/weather_platform_sheet.dart';
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
import '../widgets/weather_settings_modal.dart';
import '../widgets/weather_status_view.dart';
import '../widgets/weather_weekly_outlook_card.dart';

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({
    super.key,
    this.currentTime,
    this.atmosphereProgress,
  });

  final DateTime? currentTime;
  final double? atmosphereProgress;

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  int _selectedForecastIndex = 0;
  WeatherNavTab _currentTab = WeatherNavTab.today;
  StreamSubscription<int>? _tabSub;
  StreamSubscription<String>? _headerActionSub;

  @override
  void initState() {
    super.initState();
    WeatherNativeUIBridge.instance.initialize();
    _tabSub = WeatherNativeUIBridge.instance.onTabSelected.listen((int index) {
      if (index >= 0 && index < WeatherNavTab.values.length) {
        _onTabSelected(WeatherNavTab.values[index]);
      }
    });
    _headerActionSub = WeatherNativeUIBridge.instance.onHeaderAction.listen((
      String action,
    ) {
      if (!mounted) return;
      if (action == 'refresh') {
        WeatherScope.read(context).refresh();
      } else if (action == 'settings') {
        _openSettingsModal();
      }
    });
  }

  @override
  void dispose() {
    _tabSub?.cancel();
    _headerActionSub?.cancel();
    super.dispose();
  }

  void _onForecastSelected(int index) {
    setState(() {
      _selectedForecastIndex = index;
    });
  }

  int _getAlertCount(WeatherModel? weather) {
    if (weather == null) return 0;
    if (weather.riskLevel == 'HIGH RISK') return 2;
    if (weather.riskLevel == 'MODERATE RISK' ||
        weather.condition == WeatherCondition.storm ||
        weather.condition == WeatherCondition.rain) {
      return 1;
    }
    return 0;
  }

  void _onTabSelected(WeatherNavTab tab) {
    setState(() {
      _currentTab = tab;
    });
    final alertCount = _getAlertCount(WeatherScope.read(context).weather);
    WeatherNativeUIBridge.instance.updateNavigationState(
      NavigationState(
        selectedTab: tab.index,
        tabCount: WeatherNavTab.values.length,
        alertCount: alertCount,
      ),
    );
  }

  void _openSettingsModal() {
    WeatherPlatformSheet.show<void>(
      context: context,
      sheetType: 'settings',
      title: 'Station Intelligence & Settings',
      builder: (BuildContext ctx) => WeatherSettingsModal(
        onRefresh: () => WeatherScope.read(context).refresh(),
      ),
    );
  }

  int? _parseHourFromLabel(String label) {
    final clean = label.trim().toUpperCase();
    if (clean == 'NOW') {
      return (widget.currentTime ?? DateTime.now()).hour;
    }
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final hourNum = int.tryParse(parts[0]);
      final isPm = parts[1] == 'PM';
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
    final now = widget.currentTime ?? DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
        activeHour = (widget.currentTime ?? DateTime.now()).hour;
      }
    }

    final alertCount = _getAlertCount(weather);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: WeatherAtmosphere(
              condition: activeCondition,
              customHour: activeHour,
              animationProgress: widget.atmosphereProgress,
            ),
          ),
          SafeArea(
            bottom: false,
            child: ValueListenableBuilder<NativeInsets>(
              valueListenable: WeatherNativeUIBridge.instance.insetsNotifier,
              builder:
                  (BuildContext context, NativeInsets insets, Widget? child) {
                    return Column(
                      children: <Widget>[
                        // Top Platform Header Bar
                        if (weather != null)
                          WeatherPlatformHeader(
                            location: weather.location,
                            dateSubtitle: _formatTodayHeaderDate(),
                            isOffline: provider.isOffline,
                            onSettingsPressed: _openSettingsModal,
                          ),

                        // Main Tab Content
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  (WeatherPlatform.isIOS(context) &&
                                      WeatherNativeUIBridge
                                          .instance
                                          .isNativeBridgeAvailable)
                                  ? insets.bottom
                                  : 0.0,
                            ),
                            child: RepaintBoundary(
                              key: const ValueKey<String>(
                                'weather-content-boundary',
                              ),
                              child: _WeatherTabBody(
                                provider: provider,
                                currentTab: _currentTab,
                                selectedForecastIndex: _selectedForecastIndex,
                                onForecastSelected: _onForecastSelected,
                              ),
                            ),
                          ),
                        ),

                        // Platform Navigation Bar (M3 on Android, suppressed/fallback on iOS)
                        if (provider.state == WeatherLoadState.loaded)
                          WeatherPlatformNavigationBar(
                            currentTab: _currentTab,
                            onTabSelected: _onTabSelected,
                            alertCount: alertCount,
                          ),
                      ],
                    );
                  },
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
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
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
          WeatherNavTab.radar => const RadarView(key: ValueKey('tab_radar')),
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
