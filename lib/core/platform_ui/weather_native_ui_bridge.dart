import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'weather_native_contracts.dart';
import 'weather_platform.dart';

class WeatherNativeUIBridge {
  WeatherNativeUIBridge._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static final WeatherNativeUIBridge instance = WeatherNativeUIBridge._();

  static const MethodChannel _channel =
      MethodChannel('tech.onlytrueperspective.weatheros/native_ui');

  bool _isNativeBridgeAvailable = false;
  static bool forceFallbackMode = false;

  bool get isNativeBridgeAvailable => !forceFallbackMode && _isNativeBridgeAvailable;

  int _navigationRevision = 0;
  int get currentNavigationRevision => _navigationRevision;

  int _radarRevision = 0;
  int get currentRadarRevision => _radarRevision;

  final ValueNotifier<NativeInsets> insetsNotifier =
      ValueNotifier<NativeInsets>(NativeInsets.zero);

  final StreamController<int> _tabSelectionController =
      StreamController<int>.broadcast();
  Stream<int> get onTabSelected => _tabSelectionController.stream;

  final StreamController<int> _radarRangeController =
      StreamController<int>.broadcast();
  Stream<int> get onRadarRangeChanged => _radarRangeController.stream;

  final StreamController<void> _radarTogglePlayController =
      StreamController<void>.broadcast();
  Stream<void> get onRadarTogglePlay => _radarTogglePlayController.stream;

  final StreamController<String> _headerActionController =
      StreamController<String>.broadcast();
  Stream<String> get onHeaderAction => _headerActionController.stream;

  final StreamController<NativeSheetResult> _sheetResultController =
      StreamController<NativeSheetResult>.broadcast();
  Stream<NativeSheetResult> get onSheetResult => _sheetResultController.stream;

  Future<void> initialize() async {
    if (!WeatherPlatform.isIOS() || forceFallbackMode) {
      _isNativeBridgeAvailable = false;
      return;
    }

    try {
      final result = await _channel
          .invokeMethod<bool>('ping')
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      _isNativeBridgeAvailable = result ?? false;
    } on MissingPluginException {
      _isNativeBridgeAvailable = false;
    } on PlatformException {
      _isNativeBridgeAvailable = false;
    } on Exception {
      _isNativeBridgeAvailable = false;
    }
  }

  Future<void> updateNavigationState(NavigationState state) async {
    if (!isNativeBridgeAvailable) return;
    _navigationRevision++;
    final stateWithRevision = NavigationState(
      selectedTab: state.selectedTab,
      revision: _navigationRevision,
      tabCount: state.tabCount,
      alertCount: state.alertCount,
      isOffline: state.isOffline,
    );
    try {
      await _channel.invokeMethod<void>(
        'updateNavigationState',
        stateWithRevision.toMap(),
      );
    } catch (_) {}
  }

  Future<void> updateRadarControls(RadarControlState state) async {
    if (!isNativeBridgeAvailable) return;
    _radarRevision++;
    final stateWithRevision = RadarControlState(
      isPlaying: state.isPlaying,
      selectedRangeIndex: state.selectedRangeIndex,
      revision: _radarRevision,
      ranges: state.ranges,
    );
    try {
      await _channel.invokeMethod<void>(
        'updateRadarControls',
        stateWithRevision.toMap(),
      );
    } catch (_) {}
  }

  Future<NativeSheetResult?> presentNativeSheet(
    NativeSheetRequest request,
  ) async {
    if (!isNativeBridgeAvailable) return null;
    try {
      final res = await _channel.invokeMapMethod<dynamic, dynamic>(
        'presentNativeSheet',
        request.toMap(),
      );
      if (res != null) {
        return NativeSheetResult.fromMap(res);
      }
    } catch (_) {}
    return null;
  }

  Future<void> triggerHaptic(HapticType type) async {
    if (!isNativeBridgeAvailable) return;
    try {
      await _channel.invokeMethod<void>(
        'triggerHaptic',
        <String, dynamic>{'type': type.name},
      );
    } catch (_) {}
  }

  Future<void> setChromeVisibility({
    bool showTabBar = true,
    bool showHeader = true,
    bool showRadarControls = false,
  }) async {
    if (!isNativeBridgeAvailable) return;
    try {
      await _channel.invokeMethod<void>(
        'setChromeVisibility',
        <String, dynamic>{
          'showTabBar': showTabBar,
          'showHeader': showHeader,
          'showRadarControls': showRadarControls,
        },
      );
    } catch (_) {}
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNativeInsetsChanged':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final newInsets = NativeInsets.fromMap(args);
          // Tolerance-based deduplication to prevent unnecessary Flutter rebuild loops
          if (!insetsNotifier.value.isRoughlyEqual(newInsets, tolerance: 0.5)) {
            insetsNotifier.value = newInsets;
          }
        }
        return null;

      case 'onTabSelected':
        final tab = (call.arguments as num?)?.toInt();
        if (tab != null) {
          _tabSelectionController.add(tab);
        }
        return null;

      case 'onRadarRangeChanged':
        final range = (call.arguments as num?)?.toInt();
        if (range != null) {
          _radarRangeController.add(range);
        }
        return null;

      case 'onRadarTogglePlay':
        _radarTogglePlayController.add(null);
        return null;

      case 'onHeaderAction':
        final action = call.arguments as String? ?? '';
        _headerActionController.add(action);
        return null;

      case 'onSheetResult':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          _sheetResultController.add(NativeSheetResult.fromMap(args));
        }
        return null;

      default:
        return null;
    }
  }

  @visibleForTesting
  void simulateTabSelected(int tabIndex) {
    _tabSelectionController.add(tabIndex);
  }

  @visibleForTesting
  void simulateInsets(NativeInsets insets) {
    if (!insetsNotifier.value.isRoughlyEqual(insets, tolerance: 0.5)) {
      insetsNotifier.value = insets;
    }
  }

  @visibleForTesting
  void resetRevisions() {
    _navigationRevision = 0;
    _radarRevision = 0;
  }
}

