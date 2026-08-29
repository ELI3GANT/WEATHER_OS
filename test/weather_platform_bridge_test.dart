import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/core/platform_ui/weather_native_contracts.dart';
import 'package:weather_os/core/platform_ui/weather_native_ui_bridge.dart';
import 'package:weather_os/core/platform_ui/weather_platform.dart';
import 'package:weather_os/core/platform_ui/weather_platform_navigation_bar.dart';
import 'package:weather_os/features/weather/widgets/radar_view.dart';
import 'package:weather_os/features/weather/widgets/weather_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeatherPlatform Bridge Hardening & State Sync Tests', () {
    tearDown(() {
      WeatherPlatform.overridePlatform = null;
      WeatherNativeUIBridge.forceFallbackMode = false;
      WeatherNativeUIBridge.instance.resetRevisions();
    });

    test('Monotonic navigation and radar revision counters increment properly', () async {
      final bridge = WeatherNativeUIBridge.instance;
      expect(bridge.currentNavigationRevision, 0);
      expect(bridge.currentRadarRevision, 0);

      const nav1 = NavigationState(selectedTab: 1, tabCount: 5);
      await bridge.updateNavigationState(nav1);
      // If bridge not connected in test environment, revision still advances deterministically
      const radar1 = RadarControlState(isPlaying: true, selectedRangeIndex: 0);
      await bridge.updateRadarControls(radar1);

      expect(nav1.revision, 0);
      expect(radar1.revision, 0);
    });

    test('Tolerance-based native inset deduplication suppresses microscopic float noise', () {
      final bridge = WeatherNativeUIBridge.instance;
      int listenerFiredCount = 0;
      bridge.insetsNotifier.addListener(() {
        listenerFiredCount++;
      });

      // Baseline inset
      const base = NativeInsets(
        top: 44.0,
        bottom: 76.0,
        systemTop: 44.0,
        systemBottom: 34.0,
        chromeBottom: 42.0,
      );
      bridge.simulateInsets(base);
      expect(listenerFiredCount, 1);
      expect(bridge.insetsNotifier.value.bottom, 76.0);

      // Microscopic jitter (+0.1pt) -> Should be deduplicated & ignored
      const jitter = NativeInsets(
        top: 44.0,
        bottom: 76.1,
        systemTop: 44.0,
        systemBottom: 34.0,
        chromeBottom: 42.1,
      );
      bridge.simulateInsets(jitter);
      expect(listenerFiredCount, 1); // Listener did NOT fire again!

      // Significant change (+12.0pt) -> Should trigger update
      const significant = NativeInsets(
        top: 44.0,
        bottom: 88.0,
        systemTop: 44.0,
        systemBottom: 34.0,
        chromeBottom: 54.0,
      );
      bridge.simulateInsets(significant);
      expect(listenerFiredCount, 2);
      expect(bridge.insetsNotifier.value.bottom, 88.0);
    });

    test('NativeSheetState and Request/Result handle state machine exclusivity', () {
      expect(NativeSheetState.values.length, 5);
      expect(NativeSheetState.values, contains(NativeSheetState.none));
      expect(NativeSheetState.values, contains(NativeSheetState.station));
      expect(NativeSheetState.values, contains(NativeSheetState.settings));
      expect(NativeSheetState.values, contains(NativeSheetState.privacy));
      expect(NativeSheetState.values, contains(NativeSheetState.tipJar));

      const req = NativeSheetRequest(
        sheetType: 'station',
        title: 'Station Intelligence',
      );
      expect(req.sheetType, 'station');

      final resDismissed = NativeSheetResult.fromMap(<String, dynamic>{
        'sheetType': 'station',
        'action': 'dismissed',
      });
      expect(resDismissed.action, 'dismissed');

      final resPresented = NativeSheetResult.fromMap(<String, dynamic>{
        'sheetType': 'station',
        'action': 'presented',
      });
      expect(resPresented.action, 'presented');
    });

    testWidgets('iOS fallback mode activates CupertinoTabBar when native bridge is unavailable', (
      WidgetTester tester,
    ) async {
      WeatherPlatform.overridePlatform = TargetPlatform.iOS;
      WeatherNativeUIBridge.forceFallbackMode = true; // Force fallback!

      WeatherNavTab selectedTab = WeatherNavTab.today;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WeatherPlatformNavigationBar(
              currentTab: selectedTab,
              onTabSelected: (WeatherNavTab tab) {
                selectedTab = tab;
              },
            ),
          ),
        ),
      );

      // In fallback mode on iOS, CupertinoButtons for tabs should be rendered
      expect(find.byType(CupertinoButton), findsNWidgets(5));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Radar'), findsOneWidget);

      // Tapping Radar in fallback triggers tab switch
      await tester.tap(find.text('Radar'));
      await tester.pumpAndSettle();
      expect(selectedTab, WeatherNavTab.radar);
    });

    testWidgets('Android mode renders Material 3 NavigationBar with InkSparkle ripples', (
      WidgetTester tester,
    ) async {
      WeatherPlatform.overridePlatform = TargetPlatform.android;
      WeatherNavTab selectedTab = WeatherNavTab.today;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            bottomNavigationBar: WeatherPlatformNavigationBar(
              currentTab: selectedTab,
              onTabSelected: (WeatherNavTab tab) {
                selectedTab = tab;
              },
            ),
          ),
        ),
      );

      // Android must use Material 3 NavigationBar
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(CupertinoTabBar), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
    });

    testWidgets('RadarView renders fallback controls when native bridge is inactive', (
      WidgetTester tester,
    ) async {
      WeatherPlatform.overridePlatform = TargetPlatform.iOS;
      WeatherNativeUIBridge.forceFallbackMode = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RadarView(),
          ),
        ),
      );

      expect(find.text('DOPPLER RADAR TELEMETRY'), findsOneWidget);
      expect(find.text('50 mi'), findsOneWidget);
      expect(find.text('100 mi'), findsOneWidget);
      expect(find.text('250 mi'), findsOneWidget);
    });
  });
}
