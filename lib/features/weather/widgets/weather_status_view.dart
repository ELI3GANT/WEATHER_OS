import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_button.dart';

class WeatherLoadingView extends StatelessWidget {
  const WeatherLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Loading current weather',
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('WEATHEROS', style: WeatherType.overline),
            SizedBox(height: WeatherSpacing.space6),
            SizedBox(
              width: 34,
              child: LinearProgressIndicator(
                minHeight: 1,
                color: WeatherPalette.mistBlue,
                backgroundColor: WeatherPalette.clear,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherErrorView extends StatelessWidget {
  const WeatherErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WeatherSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('WEATHEROS', style: WeatherType.overline),
            const SizedBox(height: WeatherSpacing.space8),
            Text(
              'The atmosphere is quiet.',
              style: WeatherType.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WeatherSpacing.space3),
            Text(message, style: WeatherType.body, textAlign: TextAlign.center),
            const SizedBox(height: WeatherSpacing.space8),
            WeatherPlatformButton(
              variant: WeatherButtonVariant.primary,
              onPressed: onRetry,
              child: const Text('Retry Telemetry'),
            ),
          ],
        ),
      ),
    );
  }
}
