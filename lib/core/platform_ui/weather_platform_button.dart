import 'package:flutter/material.dart';

import '../../app/theme/weather_tokens.dart';
import 'weather_platform.dart';
import 'weather_platform_feedback.dart';

enum WeatherButtonVariant {
  primary,
  tonal,
  outlined,
  glass,
}

class WeatherPlatformButton extends StatefulWidget {
  const WeatherPlatformButton({
    required this.child,
    required this.onPressed,
    this.variant = WeatherButtonVariant.primary,
    this.icon,
    this.padding,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final WeatherButtonVariant variant;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  State<WeatherPlatformButton> createState() => _WeatherPlatformButtonState();
}

class _WeatherPlatformButtonState extends State<WeatherPlatformButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = WeatherPlatform.isIOS(context);
    final effectiveRadius = widget.borderRadius ??
        BorderRadius.circular(WeatherRadii.control);
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 18, vertical: 12);

    if (isIOS) {
      // iOS: Cupertino spring interactive button
      final backgroundColor = switch (widget.variant) {
        WeatherButtonVariant.primary => WeatherPalette.mistBlue,
        WeatherButtonVariant.tonal =>
          WeatherPalette.lensLift.withValues(alpha: 0.8),
        WeatherButtonVariant.glass =>
          WeatherPalette.lensLift.withValues(alpha: 0.35),
        WeatherButtonVariant.outlined => Colors.transparent,
      };

      final foregroundColor = switch (widget.variant) {
        WeatherButtonVariant.primary => WeatherPalette.canvasDeep,
        WeatherButtonVariant.tonal => WeatherPalette.textPrimary,
        WeatherButtonVariant.glass => WeatherPalette.textPrimary,
        WeatherButtonVariant.outlined => WeatherPalette.mistBlue,
      };

      final border = widget.variant == WeatherButtonVariant.outlined
          ? Border.all(
              color: WeatherPalette.mistBlue.withValues(alpha: 0.4),
              width: 1.2,
            )
          : (widget.variant == WeatherButtonVariant.glass
              ? Border.all(
                  color: WeatherPalette.lensRim.withValues(alpha: 0.25),
                  width: 1.0,
                )
              : null);

      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed == null
            ? null
            : () {
                WeatherPlatformFeedback.selection(context);
                widget.onPressed!();
              },
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: widget.onPressed == null
                ? 0.5
                : (_isPressed ? 0.85 : 1.0),
            duration: const Duration(milliseconds: 140),
            child: Container(
              padding: effectivePadding,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: effectiveRadius,
                border: border,
              ),
              child: DefaultTextStyle(
                style: WeatherType.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                  fontSize: 13,
                ),
                child: IconTheme(
                  data: IconThemeData(color: foregroundColor, size: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.icon != null) ...<Widget>[
                        widget.icon!,
                        const SizedBox(width: WeatherSpacing.space2),
                      ],
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Android: Material 3 Button with InkSparkle ripple
    switch (widget.variant) {
      case WeatherButtonVariant.primary:
        if (widget.icon != null) {
          return FilledButton.icon(
            onPressed: widget.onPressed,
            icon: widget.icon!,
            label: widget.child,
            style: FilledButton.styleFrom(
              backgroundColor: WeatherPalette.mistBlue,
              foregroundColor: WeatherPalette.canvasDeep,
              padding: effectivePadding,
              shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
            ),
          );
        }
        return FilledButton(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: WeatherPalette.mistBlue,
            foregroundColor: WeatherPalette.canvasDeep,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: widget.child,
        );

      case WeatherButtonVariant.tonal:
      case WeatherButtonVariant.glass:
        if (widget.icon != null) {
          return FilledButton.tonalIcon(
            onPressed: widget.onPressed,
            icon: widget.icon!,
            label: widget.child,
            style: FilledButton.styleFrom(
              backgroundColor: WeatherPalette.lensLift,
              foregroundColor: WeatherPalette.textPrimary,
              padding: effectivePadding,
              shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
            ),
          );
        }
        return FilledButton.tonal(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: WeatherPalette.lensLift,
            foregroundColor: WeatherPalette.textPrimary,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: widget.child,
        );

      case WeatherButtonVariant.outlined:
        if (widget.icon != null) {
          return OutlinedButton.icon(
            onPressed: widget.onPressed,
            icon: widget.icon!,
            label: widget.child,
            style: OutlinedButton.styleFrom(
              foregroundColor: WeatherPalette.mistBlue,
              side: BorderSide(
                color: WeatherPalette.mistBlue.withValues(alpha: 0.4),
              ),
              padding: effectivePadding,
              shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
            ),
          );
        }
        return OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: WeatherPalette.mistBlue,
            side: BorderSide(
              color: WeatherPalette.mistBlue.withValues(alpha: 0.4),
            ),
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: widget.child,
        );
    }
  }
}
