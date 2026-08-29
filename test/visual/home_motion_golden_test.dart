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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    WeatherNativeUIBridge.forceFallbackMode = true;
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

  testWidgets('ambient weather renders the mid motion frame in isolation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WeatherPlatform.overridePlatform = TargetPlatform.iOS;
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
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: const ValueKey<String>('home-motion-boundary'),
              child: WeatherHomeScreen(
                currentTime: DateTime(2026, 8, 29, 12),
                atmosphereProgress: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('home-motion-boundary')),
      matchesGoldenFile('goldens/home_motion_mid.png'),
    );
  });
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
