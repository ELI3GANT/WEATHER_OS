import 'package:flutter/foundation.dart';

@immutable
class NavigationState {
  const NavigationState({
    required this.selectedTab,
    this.revision = 0,
    this.tabCount = 5,
    this.alertCount = 0,
    this.isOffline = false,
  });

  final int selectedTab;
  final int revision;
  final int tabCount;
  final int alertCount;
  final bool isOffline;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'selectedTab': selectedTab,
        'revision': revision,
        'tabCount': tabCount,
        'alertCount': alertCount,
        'isOffline': isOffline,
      };

  factory NavigationState.fromMap(Map<dynamic, dynamic> map) {
    return NavigationState(
      selectedTab: (map['selectedTab'] as num?)?.toInt() ?? 0,
      revision: (map['revision'] as num?)?.toInt() ?? 0,
      tabCount: (map['tabCount'] as num?)?.toInt() ?? 5,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      isOffline: map['isOffline'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState &&
          runtimeType == other.runtimeType &&
          selectedTab == other.selectedTab &&
          revision == other.revision &&
          tabCount == other.tabCount &&
          alertCount == other.alertCount &&
          isOffline == other.isOffline;

  @override
  int get hashCode => Object.hash(selectedTab, revision, tabCount, alertCount, isOffline);
}

@immutable
class RadarControlState {
  const RadarControlState({
    required this.isPlaying,
    required this.selectedRangeIndex,
    this.revision = 0,
    this.ranges = const <String>['50 mi', '100 mi', '250 mi'],
  });

  final bool isPlaying;
  final int selectedRangeIndex;
  final int revision;
  final List<String> ranges;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'isPlaying': isPlaying,
        'selectedRangeIndex': selectedRangeIndex,
        'revision': revision,
        'ranges': ranges,
      };

  factory RadarControlState.fromMap(Map<dynamic, dynamic> map) {
    return RadarControlState(
      isPlaying: map['isPlaying'] as bool? ?? true,
      selectedRangeIndex: (map['selectedRangeIndex'] as num?)?.toInt() ?? 1,
      revision: (map['revision'] as num?)?.toInt() ?? 0,
      ranges: (map['ranges'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>['50 mi', '100 mi', '250 mi'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarControlState &&
          runtimeType == other.runtimeType &&
          isPlaying == other.isPlaying &&
          selectedRangeIndex == other.selectedRangeIndex &&
          revision == other.revision &&
          listEquals(ranges, other.ranges);

  @override
  int get hashCode => Object.hash(isPlaying, selectedRangeIndex, revision, Object.hashAll(ranges));
}

@immutable
class NativeInsets {
  const NativeInsets({
    this.top = 0.0,
    this.bottom = 0.0,
    this.leading = 0.0,
    this.trailing = 0.0,
    this.systemTop = 0.0,
    this.systemBottom = 0.0,
    this.chromeTop = 0.0,
    this.chromeBottom = 0.0,
  });

  static const NativeInsets zero = NativeInsets();

  final double top;
  final double bottom;
  final double leading;
  final double trailing;
  final double systemTop;
  final double systemBottom;
  final double chromeTop;
  final double chromeBottom;

  double get effectiveBottom => bottom > 0.0 ? bottom : (systemBottom + chromeBottom);
  double get effectiveTop => top > 0.0 ? top : (systemTop + chromeTop);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'top': top,
        'bottom': bottom,
        'leading': leading,
        'trailing': trailing,
        'systemTop': systemTop,
        'systemBottom': systemBottom,
        'chromeTop': chromeTop,
        'chromeBottom': chromeBottom,
      };

  factory NativeInsets.fromMap(Map<dynamic, dynamic> map) {
    final sBottom = (map['systemBottom'] as num?)?.toDouble() ?? 0.0;
    final cBottom = (map['chromeBottom'] as num?)?.toDouble() ?? 0.0;
    final b = (map['bottom'] as num?)?.toDouble() ?? (sBottom + cBottom);

    final sTop = (map['systemTop'] as num?)?.toDouble() ?? 0.0;
    final cTop = (map['chromeTop'] as num?)?.toDouble() ?? 0.0;
    final t = (map['top'] as num?)?.toDouble() ?? (sTop + cTop);

    return NativeInsets(
      top: t,
      bottom: b,
      leading: (map['leading'] as num?)?.toDouble() ?? 0.0,
      trailing: (map['trailing'] as num?)?.toDouble() ?? 0.0,
      systemTop: sTop,
      systemBottom: sBottom,
      chromeTop: cTop,
      chromeBottom: cBottom,
    );
  }

  bool isRoughlyEqual(NativeInsets other, {double tolerance = 0.5}) {
    return (top - other.top).abs() <= tolerance &&
        (bottom - other.bottom).abs() <= tolerance &&
        (leading - other.leading).abs() <= tolerance &&
        (trailing - other.trailing).abs() <= tolerance &&
        (systemTop - other.systemTop).abs() <= tolerance &&
        (systemBottom - other.systemBottom).abs() <= tolerance &&
        (chromeTop - other.chromeTop).abs() <= tolerance &&
        (chromeBottom - other.chromeBottom).abs() <= tolerance;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeInsets &&
          runtimeType == other.runtimeType &&
          top == other.top &&
          bottom == other.bottom &&
          leading == other.leading &&
          trailing == other.trailing &&
          systemTop == other.systemTop &&
          systemBottom == other.systemBottom &&
          chromeTop == other.chromeTop &&
          chromeBottom == other.chromeBottom;

  @override
  int get hashCode => Object.hash(
        top,
        bottom,
        leading,
        trailing,
        systemTop,
        systemBottom,
        chromeTop,
        chromeBottom,
      );
}

enum NativeSheetState {
  none,
  station,
  settings,
  privacy,
  tipJar,
}

@immutable
class NativeSheetRequest {
  const NativeSheetRequest({
    required this.sheetType,
    this.title = '',
    this.data = const <String, dynamic>{},
  });

  final String sheetType;
  final String title;
  final Map<String, dynamic> data;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'sheetType': sheetType,
        'title': title,
        'data': data,
      };
}

@immutable
class NativeSheetResult {
  const NativeSheetResult({
    required this.sheetType,
    required this.action,
    this.data,
  });

  final String sheetType;
  final String action;
  final Map<String, dynamic>? data;

  factory NativeSheetResult.fromMap(Map<dynamic, dynamic> map) {
    return NativeSheetResult(
      sheetType: map['sheetType'] as String? ?? '',
      action: map['action'] as String? ?? 'dismissed',
      data: (map['data'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>(),
    );
  }
}

enum HapticType {
  selection,
  light,
  medium,
  heavy,
  success,
  warning,
  error,
}

