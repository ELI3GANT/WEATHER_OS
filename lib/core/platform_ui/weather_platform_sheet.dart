import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'weather_native_contracts.dart';
import 'weather_native_ui_bridge.dart';
import 'weather_platform.dart';

abstract final class WeatherPlatformSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String sheetType = 'general',
    String title = '',
    Map<String, dynamic> data = const <String, dynamic>{},
    bool isScrollControlled = true,
  }) async {
    final isIOS = WeatherPlatform.isIOS(context);

    // If native SwiftUI bridge is active on iOS, request native sheet presentation
    if (isIOS && WeatherNativeUIBridge.instance.isNativeBridgeAvailable) {
      final res = await WeatherNativeUIBridge.instance.presentNativeSheet(
        NativeSheetRequest(
          sheetType: sheetType,
          title: title,
          data: data,
        ),
      );
      if (res != null) {
        return res.action as T?;
      }
      if (!context.mounted) return null;
    }

    if (isIOS) {
      // iOS Cupertino fallback modal presentation
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (BuildContext ctx) {
          return CupertinoPopupSurface(
            isSurfacePainted: false,
            child: Material(
              color: Colors.transparent,
              child: builder(ctx),
            ),
          );
        },
      );
    }

    // Android Material 3 Modal Bottom Sheet
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }
}
