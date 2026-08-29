import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/weather_tokens.dart';
import 'weather_platform.dart';
import 'weather_platform_feedback.dart';

class WeatherPlatformSegmentedControl<T extends Object>
    extends StatelessWidget {
  const WeatherPlatformSegmentedControl({
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
    super.key,
  });

  final Map<T, Widget> children;
  final T groupValue;
  final ValueChanged<T> onValueChanged;

  @override
  Widget build(BuildContext context) {
    final isIOS = WeatherPlatform.isIOS(context);

    if (isIOS) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: groupValue,
        onValueChanged: (T? value) {
          if (value != null && value != groupValue) {
            WeatherPlatformFeedback.selection(context);
            onValueChanged(value);
          }
        },
        backgroundColor: WeatherPalette.lensLift.withValues(alpha: 0.35),
        thumbColor: WeatherPalette.mistBlue.withValues(alpha: 0.25),
        children: children,
      );
    }

    // Android Material 3 SegmentedButton
    return SegmentedButton<T>(
      segments: children.entries.map((MapEntry<T, Widget> entry) {
        return ButtonSegment<T>(
          value: entry.key,
          label: entry.value,
        );
      }).toList(),
      selected: <T>{groupValue},
      onSelectionChanged: (Set<T> newSelection) {
        if (newSelection.isNotEmpty) {
          WeatherPlatformFeedback.selection(context);
          onValueChanged(newSelection.first);
        }
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return WeatherPalette.mistBlue.withValues(alpha: 0.22);
            }
            return WeatherPalette.lensLift.withValues(alpha: 0.3);
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return WeatherPalette.mistBlue;
            }
            return WeatherPalette.textSecondary;
          },
        ),
        side: WidgetStateProperty.all(
          BorderSide(color: WeatherPalette.lensRim.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
