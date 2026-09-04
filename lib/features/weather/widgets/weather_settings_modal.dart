import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_button.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../../../core/platform_ui/weather_platform_feedback.dart';
import '../../../core/platform_ui/weather_platform_icons.dart';
import '../../../core/platform_ui/weather_platform_switch.dart';
import '../services/support_entitlement_service.dart';
import '../services/watch_export_service.dart';
import '../services/weather_preferences_service.dart';

class WeatherSettingsModal extends StatefulWidget {
  const WeatherSettingsModal({required this.onRefresh, this.onChangeLocation, super.key});

  final VoidCallback onRefresh;
  final VoidCallback? onChangeLocation;

  @override
  State<WeatherSettingsModal> createState() => _WeatherSettingsModalState();
}

class _WeatherSettingsModalState extends State<WeatherSettingsModal> {
  final SupportEntitlementService _support = SupportEntitlementService.instance;
  StreamSubscription<SupportPurchaseNotice>? _noticeSubscription;

  @override
  void initState() {
    super.initState();
    _noticeSubscription = _support.notices.listen(_showPurchaseNotice);
    unawaited(_support.initialize());
  }

  @override
  void dispose() {
    _noticeSubscription?.cancel();
    super.dispose();
  }

  void _showPurchaseNotice(SupportPurchaseNotice notice) {
    if (!mounted || notice.type == SupportPurchaseNoticeType.canceled) return;
    final message = switch (notice.type) {
      SupportPurchaseNoticeType.purchased =>
        '${notice.tier.emoji} ${notice.tier.label} unlocked permanently. Thank you!',
      SupportPurchaseNoticeType.tipped =>
        '${notice.tier.emoji} Extra support received. You are amazing!',
      SupportPurchaseNoticeType.restored =>
        '${notice.tier.label} ownership restored.',
      SupportPurchaseNoticeType.pending =>
        'Google Play is processing your purchase.',
      SupportPurchaseNoticeType.error =>
        notice.message ?? 'The purchase could not be completed.',
      SupportPurchaseNoticeType.canceled => '',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

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
        child: SingleChildScrollView(
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
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: WeatherPalette.mistBlue.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: WeatherPalette.mistBlue.withValues(
                                alpha: 0.4,
                              ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'STATION INTELLIGENCE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WeatherType.title.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'WeatherOS • OnlyTruePerspective LLC',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WeatherType.label.copyWith(
                                  fontSize: 11,
                                  color: WeatherPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      color: WeatherPalette.success,
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
                              color: WeatherPalette.success,
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

              AnimatedBuilder(
                animation: _support,
                builder: (BuildContext context, Widget? child) {
                  return WeatherPlatformCard(
                    padding: const EdgeInsets.all(WeatherSpacing.space3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'PERMANENT SUPPORT UNLOCKS',
                              style: WeatherType.overline.copyWith(fontSize: 9),
                            ),
                            Text(
                              'NO SUBSCRIPTION',
                              style: WeatherType.label.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: WeatherPalette.horizonAmber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: WeatherSpacing.space1),
                        Text(
                          _support.entitlement == WeatherSupportTier.none
                              ? 'One payment. Yours forever. Higher tiers include every lower-tier unlock.'
                              : '${_support.entitlement.emoji} ${_support.entitlement.label} is active on this Google Play account.',
                          style: WeatherType.body.copyWith(
                            fontSize: 10,
                            color: WeatherPalette.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: WeatherSpacing.space3),
                        for (final tier in WeatherSupportTier.values.skip(
                          1,
                        )) ...<Widget>[
                          _SupportUnlockButton(
                            tier: tier,
                            price: _support.priceFor(tier),
                            isOwned: _support.owns(tier),
                            isBusy:
                                _support.isBusy &&
                                _support.productFor(tier)?.id != null,
                            canPurchase: _support.canPurchase(tier),
                            isAndroidStorefront: _support.isAndroidStorefront,
                            onTap: () {
                              WeatherPlatformFeedback.selection(context);
                              unawaited(_support.purchase(tier));
                            },
                          ),
                          if (tier != WeatherSupportTier.patron)
                            const SizedBox(height: WeatherSpacing.space2),
                        ],
                        if (_support.entitlement !=
                            WeatherSupportTier.none) ...<Widget>[
                          const SizedBox(height: WeatherSpacing.space3),
                          Text(
                            'OPTIONAL REPEATABLE TIP',
                            style: WeatherType.overline.copyWith(fontSize: 9),
                          ),
                          const SizedBox(height: WeatherSpacing.space2),
                          Row(
                            children: <Widget>[
                              for (final tier in WeatherSupportTier.values.skip(
                                1,
                              )) ...<Widget>[
                                Expanded(
                                  child: _RepeatTipButton(
                                    tier: tier,
                                    price: _support.tipPriceFor(tier),
                                    enabled: _support.canTip(tier),
                                    onTap: () {
                                      WeatherPlatformFeedback.selection(
                                        context,
                                      );
                                      unawaited(
                                        _support.purchase(
                                          tier,
                                          repeatTip: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (tier != WeatherSupportTier.patron)
                                  const SizedBox(width: WeatherSpacing.space2),
                              ],
                            ],
                          ),
                        ],
                        if (_support.errorMessage != null) ...<Widget>[
                          const SizedBox(height: WeatherSpacing.space2),
                          Text(
                            _support.errorMessage!,
                            style: WeatherType.label.copyWith(
                              fontSize: 9,
                              color: WeatherPalette.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: WeatherSpacing.space3),

              // Doppler Radar Tab Visibility Toggle
              AnimatedBuilder(
                animation: WeatherPreferencesService.instance,
                builder: (BuildContext context, Widget? child) {
                  final showRadar = WeatherPreferencesService.instance.showRadarTab;
                  return WeatherPlatformCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WeatherSpacing.space3,
                      vertical: WeatherSpacing.space2,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          WeatherPlatformIcons.radar(context),
                          size: 22,
                          color: WeatherPalette.mistBlue,
                        ),
                        const SizedBox(width: WeatherSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'DOPPLER RADAR TAB',
                                style: WeatherType.overline.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Display live precipitation radar on navigation bar',
                                style: WeatherType.body.copyWith(
                                  fontSize: 11,
                                  color: WeatherPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        WeatherPlatformSwitch(
                          value: showRadar,
                          onChanged: (bool next) {
                            WeatherPreferencesService.instance.setShowRadarTab(next);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: WeatherSpacing.space3),

              if (widget.onChangeLocation != null) ...<Widget>[
                WeatherPlatformButton(
                  icon: Icon(WeatherPlatformIcons.location(context)),
                  variant: WeatherButtonVariant.outlined,
                  onPressed: widget.onChangeLocation,
                  child: const Text('Change Location / ZIP Code'),
                ),
                const SizedBox(height: WeatherSpacing.space2),
              ],

              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...<Widget>[
                WeatherPlatformButton(
                  icon: const Icon(Icons.widgets_outlined),
                  variant: WeatherButtonVariant.outlined,
                  onPressed: () async {
                    final pinned = await WatchExportService.pinAndroidWidget();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pinned
                              ? 'Adding WeatherOS widget to your Home Screen...'
                              : 'To add widget: Long press your home screen and choose WeatherOS',
                        ),
                      ),
                    );
                  },
                  child: const Text('Add Home Screen Widget'),
                ),
                const SizedBox(height: WeatherSpacing.space2),
              ],

              // Action Buttons (Refresh Telemetry)
              WeatherPlatformButton(
                icon: Icon(WeatherPlatformIcons.sync(context)),
                variant: WeatherButtonVariant.primary,
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRefresh();
                },
                child: const Text('Sync Telemetry'),
              ),
              const SizedBox(height: WeatherSpacing.space2),

              // Version info footer
              Center(
                child: Text(
                  'WeatherOS v1.0.5 • Build 19 • OnlyTruePerspective LLC',
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

class _SupportUnlockButton extends StatelessWidget {
  const _SupportUnlockButton({
    required this.tier,
    required this.price,
    required this.isOwned,
    required this.isBusy,
    required this.canPurchase,
    required this.isAndroidStorefront,
    required this.onTap,
  });

  final WeatherSupportTier tier;
  final String price;
  final bool isOwned;
  final bool isBusy;
  final bool canPurchase;
  final bool isAndroidStorefront;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canPurchase ? onTap : null,
      borderRadius: BorderRadius.circular(WeatherRadii.control),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: WeatherPalette.lensLift.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(WeatherRadii.control),
          border: Border.all(
            color: WeatherPalette.lensRim.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Text(tier.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: WeatherSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    tier.label,
                    style: WeatherType.label.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.unlockSummary,
                    style: WeatherType.body.copyWith(
                      fontSize: 9,
                      color: WeatherPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: WeatherSpacing.space2),
            Text(
              isOwned
                  ? 'UNLOCKED'
                  : isBusy
                  ? 'WAITING'
                  : isAndroidStorefront
                  ? price
                  : 'ANDROID',
              style: WeatherType.label.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isOwned
                    ? WeatherPalette.success
                    : WeatherPalette.horizonAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatTipButton extends StatelessWidget {
  const _RepeatTipButton({
    required this.tier,
    required this.price,
    required this.enabled,
    required this.onTap,
  });

  final WeatherSupportTier tier;
  final String price;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(WeatherRadii.control),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: WeatherPalette.lensLift.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(WeatherRadii.control),
          border: Border.all(
            color: WeatherPalette.lensRim.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(tier.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              price,
              style: WeatherType.label.copyWith(
                fontSize: 10,
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
