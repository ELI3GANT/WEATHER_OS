import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'weather_platform.dart';

abstract final class WeatherPlatformIcons {
  static IconData location(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.location_solid
          : Icons.location_on_rounded;

  static IconData settings(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.slider_horizontal_3
          : Icons.tune_rounded;

  static IconData today(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.cloud_bolt_rain_fill
          : Icons.thunderstorm_rounded;

  static IconData todayOutlined(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.cloud_bolt_rain
          : Icons.thunderstorm_outlined;

  static IconData hourly(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.clock_fill
          : Icons.access_time_filled_rounded;

  static IconData hourlyOutlined(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.clock
          : Icons.access_time_rounded;

  static IconData daily(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.calendar
          : Icons.calendar_month_rounded;

  static IconData dailyOutlined(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.calendar_today
          : Icons.calendar_month_outlined;

  static IconData radar(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.antenna_radiowaves_left_right
          : Icons.radar_rounded;

  static IconData radarOutlined(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.radiowaves_right
          : Icons.radar_outlined;

  static IconData alerts(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.bell_fill
          : Icons.notifications_rounded;

  static IconData alertsOutlined(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.bell
          : Icons.notifications_none_rounded;

  static IconData warning(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.exclamationmark_triangle_fill
          : Icons.warning_amber_rounded;

  static IconData shield(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.shield_fill
          : Icons.shield_rounded;

  static IconData shieldOutlined(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.shield
          : Icons.shield_outlined;

  static IconData close(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.xmark_circle_fill
          : Icons.close_rounded;

  static IconData sync(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.arrow_2_circlepath
          : Icons.sync_rounded;

  static IconData play(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.play_circle_fill
          : Icons.play_circle_fill_rounded;

  static IconData pause(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.pause_circle_fill
          : Icons.pause_circle_filled_rounded;

  static IconData cached(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.cloud_bolt
          : Icons.cloud_off_rounded;

  static IconData sun(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.sun_max_fill
          : Icons.wb_sunny_rounded;

  static IconData moon(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.moon_fill
          : Icons.nightlight_round;

  static IconData chart(BuildContext context) =>
      WeatherPlatform.isIOS(context)
          ? CupertinoIcons.chart_bar_fill
          : Icons.auto_graph_rounded;
}
