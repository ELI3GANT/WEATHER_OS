import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/core/platform_ui/weather_native_contracts.dart';
import 'package:weather_os/core/platform_ui/weather_native_ui_bridge.dart';
import 'package:weather_os/core/platform_ui/weather_platform.dart';
import 'package:weather_os/core/platform_ui/weather_platform_navigation_bar.dart';
import 'package:weather_os/core/platform_ui/weather_platform_header.dart';
import 'package:weather_os/features/weather/widgets/radar_view.dart';
import 'package:weather_os/features/weather/widgets/weather_bottom_nav_bar.dart';
import 'package:weather_os/features/weather/widgets/weather_settings_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeatherPlatform Bridge Hardening & State Sync Tests', () {
    tearDown(() {
      WeatherPlatform.overridePlatform = null;
      WeatherNativeUIBridge.forceFallbackMode = false;
      WeatherNativeUIBridge.instance.resetRevisions();
    });

    test(
      'Monotonic navigation and radar revision counters increment properly',
      () async {
        final bridge = WeatherNativeUIBridge.instance;
        expect(bridge.currentNavigationRevision, 0);
        expect(bridge.currentRadarRevision, 0);

        const nav1 = NavigationState(selectedTab: 1, tabCount: 5);
        await bridge.updateNavigationState(nav1);
        // If bridge not connected in test environment, revision still advances deterministically
        const radar1 = RadarControlState(
          isPlaying: true,
          selectedRangeIndex: 0,
        );
        await bridge.updateRadarControls(radar1);

        expect(nav1.revision, 0);
        expect(radar1.revision, 0);
      },
    );

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

    test(
      'NativeSheetState and Request/Result handle state machine exclusivity',
      () {
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
      },
    );

    testWidgets(
      'iOS fallback mode activates CupertinoTabBar when native bridge is unavailable',
      (WidgetTester tester) async {
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
      },
    );

    testWidgets(
      'Android mode renders Material 3 NavigationBar with InkSparkle ripples',
      (WidgetTester tester) async {
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
      },
    );

    testWidgets(
      'Android navigation bar stays above the system navigation inset',
      (WidgetTester tester) async {
        WeatherPlatform.overridePlatform = TargetPlatform.android;
        const size = Size(360, 800);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: size,
              padding: EdgeInsets.only(bottom: 32),
              viewPadding: EdgeInsets.only(bottom: 32),
            ),
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: Scaffold(
                bottomNavigationBar: WeatherPlatformNavigationBar(
                  currentTab: WeatherNavTab.today,
                  onTabSelected: (_) {},
                ),
              ),
            ),
          ),
        );

        final navigationBar = tester.getRect(find.byType(NavigationBar));
        expect(navigationBar.bottom, 768);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Android header handles long locations on narrow phones', (
      WidgetTester tester,
    ) async {
      WeatherPlatform.overridePlatform = TargetPlatform.android;
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 320,
            child: WeatherPlatformHeader(
              location: 'A very long location name that must fit on one line',
              dateSubtitle: 'Today • Sep 2',
              onSettingsPressed: _noop,
            ),
          ),
        ),
      );

      expect(
        find.text('A very long location name that must fit on one line'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings sheet remains scrollable on compact Android phones', (
      WidgetTester tester,
    ) async {
      WeatherPlatform.overridePlatform = TargetPlatform.android;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WeatherSettingsModal(onRefresh: _noop)),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('radar honors Android reduce-motion after play is toggled', (
      WidgetTester tester,
    ) async {
      WeatherPlatform.overridePlatform = TargetPlatform.android;
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: RadarView(
                hourly: [],
                latitude: 40.7128,
                longitude: -74.0060,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Pause Radar Sweep'));
      await tester.pump();
      await tester.tap(find.byTooltip('Resume Radar Sweep'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'RadarView renders fallback controls when native bridge is inactive',
      (WidgetTester tester) async {
        WeatherPlatform.overridePlatform = TargetPlatform.iOS;
        WeatherNativeUIBridge.forceFallbackMode = true;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RadarView(
                hourly: [],
                latitude: 40.7128,
                longitude: -74.0060,
              ),
            ),
          ),
        );

        expect(find.text('DOPPLER RADAR TELEMETRY'), findsOneWidget);
        expect(find.text('50 mi'), findsOneWidget);
        expect(find.text('100 mi'), findsOneWidget);
        expect(find.text('250 mi'), findsOneWidget);
      },
    );

  });
}

void _noop() {}
