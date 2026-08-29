import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/weather_tokens.dart';
import 'weather_platform.dart';
import 'weather_platform_feedback.dart';

class WeatherPlatformSwitch extends StatelessWidget {
  const WeatherPlatformSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isIOS = WeatherPlatform.isIOS(context);

    if (isIOS) {
      return CupertinoSwitch(
        value: value,
        activeTrackColor: WeatherPalette.mistBlue,
        onChanged: onChanged == null
            ? null
            : (bool nextVal) {
                WeatherPlatformFeedback.selection(context);
                onChanged!(nextVal);
              },
      );
    }

    return Switch(
      value: value,
      activeThumbColor: WeatherPalette.mistBlue,
      activeTrackColor: WeatherPalette.mistBlue.withValues(alpha: 0.4),
      onChanged: onChanged == null
          ? null
          : (bool nextVal) {
              WeatherPlatformFeedback.selection(context);
              onChanged!(nextVal);
            },
    );
  }
}
