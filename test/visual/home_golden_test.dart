import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/theme/weather_theme.dart';
import 'package:weather_os/core/platform_ui/weather_native_ui_bridge.dart';
import 'package:weather_os/core/platform_ui/weather_platform.dart';
import 'package:weather_os/features/weather/models/mock_weather.dart';
import 'package:weather_os/features/weather/models/weather_model.dart';
import 'package:weather_os/features/weather/providers/weather_provider.dart';
import 'package:weather_os/features/weather/providers/weather_scope.dart';
import 'package:weather_os/features/weather/screens/weather_home_screen.dart';
import 'package:weather_os/features/weather/services/weather_repository.dart';
import 'package:weather_os/features/weather/services/weather_service.dart';
import 'package:weather_os/features/weather/widgets/hourly_forecast_rail.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Force fallback mode so WeatherHomeScreen.initState() never attempts
    // the native MethodChannel ping (which would hang with no iOS host).
    WeatherNativeUIBridge.forceFallbackMode = true;

    // Stub the native_ui channel to return false for any call, preventing
    // any accidental channel invocation from blocking the test VM.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('tech.onlytrueperspective.weatheros/native_ui'),
          (MethodCall call) async => false,
        );

    final fontLoader = FontLoader('Barlow')
      ..addFont(rootBundle.load('assets/fonts/Barlow-Light.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-Bold.ttf'));
    await fontLoader.load();
  });

  tearDownAll(() {
    WeatherNativeUIBridge.forceFallbackMode = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('tech.onlytrueperspective.weatheros/native_ui'),
          null,
        );
  });

  testWidgets('ambient weather renders the start motion frame', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(390, 844),
      disableAnimations: true,
      atmosphereProgress: 0.0,
      platform: TargetPlatform.iOS,
    );
    await expectLater(
      find.byKey(const ValueKey<String>('home-boundary')),
      matchesGoldenFile('goldens/home_motion_start.png'),
    );
  });

  for (final scenario in <({String name, Size size, TargetPlatform platform})>[
    (
      name: 'compact_ios',
      size: const Size(390, 844),
      platform: TargetPlatform.iOS,
    ),
    (
      name: 'compact_android',
      size: const Size(360, 800),
      platform: TargetPlatform.android,
    ),
    (
      name: 'medium',
      size: const Size(768, 1024),
      platform: TargetPlatform.android,
    ),
    (
      name: 'expanded',
      size: const Size(1280, 900),
      platform: TargetPlatform.android,
    ),
  ]) {
    testWidgets('home renders at ${scenario.name} size', (
      WidgetTester tester,
    ) async {
      await _pumpHome(
        tester,
        size: scenario.size,
        disableAnimations: true,
        platform: scenario.platform,
      );

      if (scenario.name == 'compact_android') {
        final forecastRail = tester.getRect(find.byType(HourlyForecastRail));
        final noonTime = tester.getRect(find.text('12 PM'));
        expect(noonTime.right, lessThanOrEqualTo(forecastRail.right - 16));
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('home-boundary')),
        matchesGoldenFile('goldens/home_${scenario.name}.png'),
      );
    });
  }

  testWidgets('compact Android navigation keeps every tab usable', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(360, 800),
      disableAnimations: true,
      platform: TargetPlatform.android,
    );

    for (final label in <String>[
      'Hourly',
      'Daily',
      'Radar',
      'Alerts',
      'Today',
    ]) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tab $label');
    }
  });

  testWidgets('short home scroll keeps metrics reachable', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(320, 640),
      disableAnimations: true,
      platform: TargetPlatform.iOS,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();

    expect(find.text('IMPACT METER'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('home-boundary')),
      matchesGoldenFile('goldens/home_short_lower.png'),
    );
  });

  testWidgets('home remains complete at large accessibility text', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(390, 844),
      disableAnimations: true,
      platform: TargetPlatform.iOS,
      textScaler: const TextScaler.linear(1.8),
    );
    expect(find.text('New York, NY'), findsOneWidget);
    expect(find.text('71°'), findsAtLeastNWidgets(2));
    expect(find.text('Rain'), findsOneWidget);
    expect(find.text('Feels like 69°'), findsOneWidget);
    expect(find.textContaining('H 72°'), findsOneWidget);
    final hourlyHeading = find.text('HOURLY FORECAST');
    final liveRadarSync = find.text('LIVE RADAR SYNC');
    expect(
      tester.getTopLeft(liveRadarSync).dy,
      greaterThan(tester.getTopLeft(hourlyHeading).dy),
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('home-boundary')),
      matchesGoldenFile('goldens/home_large_text.png'),
    );
  });

  testWidgets('home large text keeps lower impact content reachable', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(390, 844),
      disableAnimations: true,
      platform: TargetPlatform.iOS,
      textScaler: const TextScaler.linear(1.8),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();

    expect(find.text('IMPACT METER'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('home-boundary')),
      matchesGoldenFile('goldens/home_large_text_lower.png'),
    );
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required bool disableAnimations,
  required TargetPlatform platform,
  Duration initialPump = Duration.zero,
  double? atmosphereProgress,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  WeatherPlatform.overridePlatform = platform;
  addTearDown(() => WeatherPlatform.overridePlatform = null);

  final provider = WeatherProvider(
    repository: const WeatherRepository(
      service: _StaticWeatherService(MockWeather.newYorkRain),
    ),
    cacheService: null,
    telemetryExporter: _discardWeather,
  );
  await provider.load();
  addTearDown(provider.dispose);

  await tester.pumpWidget(
    WeatherScope(
      provider: provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: WeatherTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
            textScaler: textScaler,
          ),
          child: RepaintBoundary(
            key: ValueKey<String>('home-boundary'),
            child: WeatherHomeScreen(
              currentTime: DateTime(2026, 8, 29, 12),
              atmosphereProgress: atmosphereProgress,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(initialPump);
}

Future<void> _discardWeather(WeatherModel _) async {}

class _StaticWeatherService implements WeatherService {
  const _StaticWeatherService(this.weather);

  final WeatherModel weather;

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) async => weather;
}
