import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: WeatherPalette.canvasDeep.withValues(alpha: 0.90),
        border: Border(
          top: BorderSide(
            color: WeatherPalette.lensRim.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: WeatherSpacing.space2,
                horizontal: WeatherSpacing.space2,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _NavItem(
                      icon: Icons.thunderstorm_outlined,
                      activeIcon: Icons.thunderstorm_rounded,
                      label: 'Today',
                      isSelected: currentTab == WeatherNavTab.today,
                      onTap: () => onTabSelected(WeatherNavTab.today),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.access_time_rounded,
                      activeIcon: Icons.access_time_filled_rounded,
                      label: 'Hourly',
                      isSelected: currentTab == WeatherNavTab.hourly,
                      onTap: () => onTabSelected(WeatherNavTab.hourly),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: 'Daily',
                      isSelected: currentTab == WeatherNavTab.daily,
                      onTap: () => onTabSelected(WeatherNavTab.daily),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.radar_outlined,
                      activeIcon: Icons.radar_rounded,
                      label: 'Radar',
                      isSelected: currentTab == WeatherNavTab.radar,
                      onTap: () => onTabSelected(WeatherNavTab.radar),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.notifications_none_rounded,
                      activeIcon: Icons.notifications_rounded,
                      label: 'Alerts',
                      badgeCount: alertCount > 0 ? alertCount : null,
                      isSelected: currentTab == WeatherNavTab.alerts,
                      onTap: () => onTabSelected(WeatherNavTab.alerts),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeIcon,
    this.badgeCount,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final activeColor = isSelected ? WeatherPalette.mistBlue : WeatherPalette.textTertiary;
    final displayedIcon = (isSelected && activeIcon != null) ? activeIcon! : icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WeatherRadii.control),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? WeatherPalette.mistBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(WeatherRadii.control),
          border: isSelected
              ? Border.all(
                  color: WeatherPalette.mistBlue.withValues(alpha: 0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Icon(displayedIcon, size: 22, color: activeColor),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5252),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$badgeCount',
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
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: WeatherType.label.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
