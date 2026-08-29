import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/weather_tokens.dart';
import '../../features/weather/widgets/weather_bottom_nav_bar.dart';
import 'weather_native_contracts.dart';
import 'weather_native_ui_bridge.dart';
import 'weather_platform.dart';
import 'weather_platform_feedback.dart';
import 'weather_platform_icons.dart';

class WeatherPlatformNavigationBar extends StatelessWidget {
  const WeatherPlatformNavigationBar({
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
    final isIOS = WeatherPlatform.isIOS(context);

    // If native SwiftUI bridge is actively hosting chrome on iOS, do not render duplicate Flutter tab bar
    if (isIOS && WeatherNativeUIBridge.instance.isNativeBridgeAvailable) {
      // Synchronize confirmed state to native SwiftUI chrome
      WeatherNativeUIBridge.instance.updateNavigationState(
        NavigationState(
          selectedTab: currentTab.index,
          tabCount: WeatherNavTab.values.length,
          alertCount: alertCount,
        ),
      );
      return const SizedBox.shrink();
    }

    if (isIOS) {
      // iOS Cupertino / Glass Fallback Navigation Bar
      return Container(
        decoration: BoxDecoration(
          color: WeatherPalette.canvasDeep.withValues(alpha: 0.85),
          border: Border(
            top: BorderSide(
              color: WeatherPalette.lensRim.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: WeatherSpacing.space2,
                  horizontal: WeatherSpacing.space2,
                ),
                child: Row(
                  children: WeatherNavTab.values.map((WeatherNavTab tab) {
                    final isSelected = tab == currentTab;
                    return Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          WeatherPlatformFeedback.selection(context);
                          onTabSelected(tab);
                        },
                        child: _IOSNavItem(
                          tab: tab,
                          isSelected: isSelected,
                          alertCount: tab == WeatherNavTab.alerts ? alertCount : 0,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Android: Material 3 NavigationBar with InkSparkle ripple
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: WeatherPalette.canvasDeep.withValues(alpha: 0.95),
        indicatorColor: WeatherPalette.mistBlue.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return WeatherType.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: WeatherPalette.mistBlue,
              );
            }
            return WeatherType.label.copyWith(
              fontSize: 11,
              color: WeatherPalette.textTertiary,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: WeatherPalette.mistBlue,
                size: 24,
              );
            }
            return const IconThemeData(
              color: WeatherPalette.textTertiary,
              size: 24,
            );
          },
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (int index) {
          WeatherPlatformFeedback.selection(context);
          onTabSelected(WeatherNavTab.values[index]);
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Icon(WeatherPlatformIcons.todayOutlined(context)),
            selectedIcon: Icon(WeatherPlatformIcons.today(context)),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(WeatherPlatformIcons.hourlyOutlined(context)),
            selectedIcon: Icon(WeatherPlatformIcons.hourly(context)),
            label: 'Hourly',
          ),
          NavigationDestination(
            icon: Icon(WeatherPlatformIcons.dailyOutlined(context)),
            selectedIcon: Icon(WeatherPlatformIcons.daily(context)),
            label: 'Daily',
          ),
          NavigationDestination(
            icon: Icon(WeatherPlatformIcons.radarOutlined(context)),
            selectedIcon: Icon(WeatherPlatformIcons.radar(context)),
            label: 'Radar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              backgroundColor: const Color(0xFFFF5252),
              child: Icon(WeatherPlatformIcons.alertsOutlined(context)),
            ),
            selectedIcon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              backgroundColor: const Color(0xFFFF5252),
              child: Icon(WeatherPlatformIcons.alerts(context)),
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

class _IOSNavItem extends StatelessWidget {
  const _IOSNavItem({
    required this.tab,
    required this.isSelected,
    this.alertCount = 0,
  });

  final WeatherNavTab tab;
  final bool isSelected;
  final int alertCount;

  IconData _iconForTab(BuildContext context) {
    return switch (tab) {
      WeatherNavTab.today => isSelected
          ? WeatherPlatformIcons.today(context)
          : WeatherPlatformIcons.todayOutlined(context),
      WeatherNavTab.hourly => isSelected
          ? WeatherPlatformIcons.hourly(context)
          : WeatherPlatformIcons.hourlyOutlined(context),
      WeatherNavTab.daily => isSelected
          ? WeatherPlatformIcons.daily(context)
          : WeatherPlatformIcons.dailyOutlined(context),
      WeatherNavTab.radar => isSelected
          ? WeatherPlatformIcons.radar(context)
          : WeatherPlatformIcons.radarOutlined(context),
      WeatherNavTab.alerts => isSelected
          ? WeatherPlatformIcons.alerts(context)
          : WeatherPlatformIcons.alertsOutlined(context),
    };
  }

  String _labelForTab() {
    return switch (tab) {
      WeatherNavTab.today => 'Today',
      WeatherNavTab.hourly => 'Hourly',
      WeatherNavTab.daily => 'Daily',
      WeatherNavTab.radar => 'Radar',
      WeatherNavTab.alerts => 'Alerts',
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isSelected ? WeatherPalette.mistBlue : WeatherPalette.textTertiary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Icon(_iconForTab(context), size: 22, color: activeColor),
            if (alertCount > 0)
              Positioned(
                top: -3,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    '$alertCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          _labelForTab(),
          style: WeatherType.label.copyWith(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: activeColor,
          ),
        ),
      ],
    );
  }
}
