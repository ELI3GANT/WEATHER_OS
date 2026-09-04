import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_native_contracts.dart';
import '../../../core/platform_ui/weather_native_ui_bridge.dart';
import '../../../core/platform_ui/weather_platform.dart';
import '../../../core/platform_ui/weather_platform_header.dart';
import '../../../core/platform_ui/weather_platform_navigation_bar.dart';
import '../../../core/platform_ui/weather_platform_sheet.dart';
import '../models/mock_weather.dart';
import '../models/weather_atmosphere_state.dart';
import '../models/weather_condition.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../providers/weather_scope.dart';
import '../services/location_search_service.dart';
import '../services/weather_preferences_service.dart';
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
    this.initialTab = WeatherNavTab.today,
  });

  final DateTime? currentTime;
  final double? atmosphereProgress;
  final WeatherNavTab initialTab;

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  int _selectedForecastIndex = 0;
  late WeatherNavTab _currentTab;
  String? _lastLoadedLocation;
  StreamSubscription<int>? _tabSub;
  StreamSubscription<String>? _headerActionSub;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    WeatherNativeUIBridge.instance.initialize();
    WeatherPreferencesService.instance.addListener(_handlePreferencesChanged);
    _tabSub = WeatherNativeUIBridge.instance.onTabSelected.listen((int index) {
      final showRadar = WeatherPreferencesService.instance.showRadarTab;
      final availableTabs = WeatherNavTab.values
          .where((t) => showRadar || t != WeatherNavTab.radar)
          .toList();
      if (mounted && index >= 0 && index < availableTabs.length) {
        _onTabSelected(availableTabs[index]);
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
    WeatherPreferencesService.instance.removeListener(_handlePreferencesChanged);
    _tabSub?.cancel();
    _headerActionSub?.cancel();
    super.dispose();
  }

  void _handlePreferencesChanged() {
    if (!mounted) return;
    if (!WeatherPreferencesService.instance.showRadarTab &&
        _currentTab == WeatherNavTab.radar) {
      setState(() {
        _currentTab = WeatherNavTab.today;
      });
    } else {
      setState(() {});
    }
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
    if (!mounted) return;
    setState(() {
      _currentTab = tab;
    });
    final alertCount = _getAlertCount(WeatherScope.read(context).weather);
    final showRadar = WeatherPreferencesService.instance.showRadarTab;
    final availableTabs = WeatherNavTab.values
        .where((t) => showRadar || t != WeatherNavTab.radar)
        .toList();
    final tabIndex = availableTabs.indexOf(tab);
    WeatherNativeUIBridge.instance.updateNavigationState(
      NavigationState(
        selectedTab: tabIndex >= 0 ? tabIndex : 0,
        tabCount: availableTabs.length,
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
        onChangeLocation: () {
          // Dismiss the modal bottom sheet cleanly before opening the location dialog
          Navigator.of(ctx, rootNavigator: true).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openLocationChooser();
            }
          });
        },
      ),
    );
  }

  Future<void> _openLocationChooser() async {
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _LocationInputDialog(),
    );
    if (!mounted || query == null || query.trim().isEmpty) return;
    final result = await const LocationSearchService().search(query);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not found. Try a ZIP code or city.'),
        ),
      );
      return;
    }
    setState(() {
      _selectedForecastIndex = 0;
    });
    await WeatherScope.read(context).setLocation(result);
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

    if (weather != null && weather.location != _lastLoadedLocation) {
      _lastLoadedLocation = weather.location;
      _selectedForecastIndex = 0;
    }

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
    final sceneWeather = weather ?? MockWeather.newYorkRain;
    final atmosphereState = WeatherAtmosphereState.fromWeather(
      sceneWeather,
      now: widget.currentTime ?? DateTime.now(),
    );

    return PopScope(
      canPop: _currentTab == WeatherNavTab.today,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _currentTab != WeatherNavTab.today) {
          setState(() {
            _currentTab = WeatherNavTab.today;
          });
        }
      },
      child: Scaffold(
        body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: WeatherAtmosphere(
              condition: activeCondition,
              customHour: activeHour,
              animationProgress: widget.atmosphereProgress,
              atmosphereState: atmosphereState,
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
                            onLocationPressed: _openLocationChooser,
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
                            showRadar: WeatherPreferencesService.instance.showRadarTab,
                          ),
                      ],
                    );
                  },
            ),
          ),
        ],
      ),
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
        child: provider.weather == null
            ? const WeatherLoadingView()
            : switch (currentTab) {
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
                WeatherNavTab.radar => RadarView(
                  key: const ValueKey('tab_radar'),
                  hourly: provider.weather!.hourly,
                  latitude: provider.latitude,
                  longitude: provider.longitude,
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
    if (weather.hourly.isNotEmpty &&
        selectedForecastIndex > 0 &&
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

class _LocationInputDialog extends StatefulWidget {
  const _LocationInputDialog();

  @override
  State<_LocationInputDialog> createState() => _LocationInputDialogState();
}

class _LocationInputDialogState extends State<_LocationInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change weather location'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'ZIP code, city, or state',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Use location'),
        ),
      ],
    );
  }
}

