import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_button.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../../../core/platform_ui/weather_platform_feedback.dart';
import '../../../core/platform_ui/weather_platform_icons.dart';

class WeatherSettingsModal extends StatelessWidget {
  const WeatherSettingsModal({
    required this.onRefresh,
    super.key,
  });

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WeatherPalette.canvasDeep.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: WeatherPalette.mistBlue.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WeatherSpacing.space5,
            vertical: WeatherSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Modal drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WeatherPalette.textTertiary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(WeatherRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: WeatherSpacing.space4),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: WeatherPalette.mistBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: WeatherPalette.mistBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            WeatherPlatformIcons.settings(context),
                            size: 18,
                            color: WeatherPalette.mistBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: WeatherSpacing.space2),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'STATION INTELLIGENCE',
                            style: WeatherType.title.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'WeatherOS • OnlyTruePerspective LLC',
                            style: WeatherType.label.copyWith(
                              fontSize: 11,
                              color: WeatherPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(WeatherPlatformIcons.close(context), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: WeatherSpacing.space4),

              // Zero-Subscription Pledge Card
              WeatherPlatformCard(
                padding: const EdgeInsets.all(WeatherSpacing.space3),
                child: Row(
                  children: <Widget>[
                    Icon(
                      WeatherPlatformIcons.shield(context),
                      size: 24,
                      color: const Color(0xFF69F0AE),
                    ),
                    const SizedBox(width: WeatherSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'PROUDLY 100% AD-FREE & PRIVATE',
                            style: WeatherType.overline.copyWith(
                              fontSize: 9,
                              color: const Color(0xFF69F0AE),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No subscriptions, no third-party data tracking, and zero advertising algorithms.',
                            style: WeatherType.body.copyWith(
                              fontSize: 11,
                              color: WeatherPalette.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WeatherSpacing.space3),

              // Optional Creator Tip Jar Section
              WeatherPlatformCard(
                padding: const EdgeInsets.all(WeatherSpacing.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'SUPPORT INDEPENDENT DEVELOPMENT',
                          style: WeatherType.overline.copyWith(fontSize: 9),
                        ),
                        Text(
                          'OPTIONAL',
                          style: WeatherType.label.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: WeatherPalette.horizonAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WeatherSpacing.space2),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _TipJarButton(
                            emoji: '☕',
                            title: 'Coffee',
                            amount: '\$1.99',
                            onTap: () {
                              WeatherPlatformFeedback.selection(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you for supporting independent software! ☕✨'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: WeatherSpacing.space2),
                        Expanded(
                          child: _TipJarButton(
                            emoji: '⚡',
                            title: 'Supercharge',
                            amount: '\$4.99',
                            onTap: () {
                              WeatherPlatformFeedback.selection(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Supercharge support received! You rock! ⚡🚀'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: WeatherSpacing.space2),
                        Expanded(
                          child: _TipJarButton(
                            emoji: '👑',
                            title: 'Patron',
                            amount: '\$9.99',
                            onTap: () {
                              WeatherPlatformFeedback.selection(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP Founding Patron status acknowledged! 👑💎'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WeatherSpacing.space3),

              // Action Buttons (Refresh Telemetry)
              WeatherPlatformButton(
                icon: Icon(WeatherPlatformIcons.sync(context)),
                variant: WeatherButtonVariant.primary,
                onPressed: () {
                  Navigator.of(context).pop();
                  onRefresh();
                },
                child: const Text('Sync Telemetry'),
              ),
              const SizedBox(height: WeatherSpacing.space2),

              // Version info footer
              Center(
                child: Text(
                  'WeatherOS v1.0.3 • Build 17 • OnlyTruePerspective LLC',
                  style: WeatherType.label.copyWith(
                    fontSize: 10,
                    color: WeatherPalette.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipJarButton extends StatelessWidget {
  const _TipJarButton({
    required this.emoji,
    required this.title,
    required this.amount,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WeatherRadii.control),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: WeatherPalette.lensLift.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(WeatherRadii.control),
          border: Border.all(
            color: WeatherPalette.lensRim.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              title,
              style: WeatherType.label.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              amount,
              style: WeatherType.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: WeatherPalette.horizonAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
