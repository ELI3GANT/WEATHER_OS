import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/weather_tokens.dart';
import 'weather_platform.dart';
import 'weather_platform_feedback.dart';
import 'weather_platform_icons.dart';

class WeatherPlatformHeader extends StatelessWidget {
  const WeatherPlatformHeader({
    required this.location,
    required this.dateSubtitle,
    required this.onSettingsPressed,
    this.onLocationPressed,
    this.isOffline = false,
    super.key,
  });

  final String location;
  final String dateSubtitle;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onLocationPressed;
  final bool isOffline;

  Widget _locationContent(BuildContext context, {required double fontSize}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WeatherType.title.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: fontSize == 17 ? -0.3 : null,
              color: WeatherPalette.textPrimary,
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  dateSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WeatherType.label.copyWith(
                    fontSize: 11,
                    color: WeatherPalette.textSecondary,
                  ),
                ),
              ),
              if (isOffline) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: WeatherPalette.horizonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(WeatherRadii.pill),
                    border: Border.all(
                      color: WeatherPalette.horizonAmber.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        WeatherPlatformIcons.cached(context),
                        size: 10,
                        color: WeatherPalette.horizonAmber,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'CACHED',
                        style: WeatherType.label.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: WeatherPalette.horizonAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = WeatherPlatform.isIOS(context);
    final settingsButton = isIOS
        ? CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () {
              WeatherPlatformFeedback.selection(context);
              onSettingsPressed();
            },
            child: Icon(
              WeatherPlatformIcons.settings(context),
              size: 20,
              color: WeatherPalette.textPrimary,
            ),
          )
        : IconButton(
            icon: Icon(
              WeatherPlatformIcons.settings(context),
              color: WeatherPalette.textPrimary,
            ),
            onPressed: () {
              WeatherPlatformFeedback.selection(context);
              onSettingsPressed();
            },
            tooltip: 'Station Intelligence & Settings',
          );

    final locationWidget = Row(
      children: <Widget>[
        Icon(
          WeatherPlatformIcons.location(context),
          size: isIOS ? 18 : 20,
          color: WeatherPalette.mistBlue,
        ),
        const SizedBox(width: WeatherSpacing.space2),
        _locationContent(context, fontSize: isIOS ? 17 : 16),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WeatherSpacing.space4,
        vertical: WeatherSpacing.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: onLocationPressed != null
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      WeatherPlatformFeedback.selection(context);
                      onLocationPressed!();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: locationWidget,
                    ),
                  )
                : locationWidget,
          ),
          settingsButton,
        ],
      ),
    );
  }
}
