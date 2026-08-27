import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/weather_os_app.dart';
import 'package:weather_os/features/weather/widgets/weather_status_view.dart';

void main() {
  testWidgets('WeatherOS loads the current conditions experience', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WeatherOsApp(cacheService: null));
    expect(find.byType(WeatherLoadingView), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byType(WeatherLoadingView), findsNothing);
    expect(find.text('Woonsocket, RI'), findsOneWidget);
    expect(find.text('71°'), findsAtLeastNWidgets(1));
    expect(find.text('Rain'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}
