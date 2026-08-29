import 'package:flutter/material.dart';

import '../../../core/platform_ui/weather_platform_navigation_bar.dart';

enum WeatherNavTab { today, hourly, daily, radar, alerts }

class WeatherBottomNavBar extends StatelessWidget {
  const WeatherBottomNavBar({
    required this.currentTab,
    required this.onTabSelected,
    this.alertCount = 0,
    super.key,
  });

  final WeatherNavTab currentTab;
  final ValueChanged<WeatherNavTab> onTabSelected;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return WeatherPlatformNavigationBar(
      currentTab: currentTab,
      onTabSelected: onTabSelected,
      alertCount: alertCount,
    );
  }
}
