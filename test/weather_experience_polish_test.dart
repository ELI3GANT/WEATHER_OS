import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/theme/weather_theme.dart';
import 'package:weather_os/features/weather/models/condition_fixtures.dart';
import 'package:weather_os/features/weather/models/weather_atmosphere_state.dart';
import 'package:weather_os/features/weather/widgets/current_conditions_hero.dart';
import 'package:weather_os/features/weather/widgets/weather_atmosphere.dart';

void main() {
  group('WeatherAtmosphereState - Condition & Presentation Derivations', () {
    test('clearDay derives clear family, daytime phase, and luminous storyline', () {
      final state = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.clearDay,
        now: DateTime(2026, 8, 29, 12, 0),
      );

      expect(state.conditionFamily, WeatherConditionFamily.clear);
      expect(state.daylightPhase, DaylightPhase.day);
      expect(state.cloudIntensity, lessThanOrEqualTo(0.25));
      expect(state.precipitationIntensity, equals(0.0));
      expect(state.storyLine.toLowerCase(), contains('clear'));
    });

    test('clearNight derives clear family and night phase with star storytelling', () {
      final state = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.clearNight,
        now: DateTime(2026, 8, 29, 23, 0),
      );

      expect(state.conditionFamily, WeatherConditionFamily.clear);
      expect(state.daylightPhase, DaylightPhase.night);
      expect(state.storyLine.toLowerCase(), contains('night'));
    });

    test('partlyCloudyDay vs overcast are cleanly differentiated', () {
      final partlyCloudyState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.partlyCloudyDay,
        now: DateTime(2026, 8, 29, 12, 0),
      );
      final overcastState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.overcast,
        now: DateTime(2026, 8, 29, 12, 0),
      );

      expect(partlyCloudyState.conditionFamily, WeatherConditionFamily.cloudy);
      expect(partlyCloudyState.isOvercast, isFalse);
      expect(partlyCloudyState.storyLine, contains('Partly cloudy'));

      expect(overcastState.conditionFamily, WeatherConditionFamily.cloudy);
      expect(overcastState.isOvercast, isTrue);
      expect(overcastState.cloudIntensity, greaterThan(partlyCloudyState.cloudIntensity));
      expect(overcastState.storyLine, contains('Overcast'));
    });

    test('lightRain vs heavyRain scale precipitation intensity and storytelling', () {
      final lightState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.lightRain,
        now: DateTime(2026, 8, 29, 14, 0),
      );
      final heavyState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.heavyRain,
        now: DateTime(2026, 8, 29, 14, 0),
      );

      expect(lightState.conditionFamily, WeatherConditionFamily.rain);
      expect(lightState.isHeavyPrecipitation, isFalse);
      expect(lightState.storyLine, contains('Light rain'));

      expect(heavyState.conditionFamily, WeatherConditionFamily.rain);
      expect(heavyState.isHeavyPrecipitation, isTrue);
      expect(heavyState.precipitationIntensity, greaterThan(lightState.precipitationIntensity));
      expect(heavyState.storyLine, contains('Heavy'));
    });

    test('thunderstorm derives high severe intensity and storm storytelling', () {
      final stormState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.thunderstorm,
        now: DateTime(2026, 8, 29, 17, 0),
      );

      expect(stormState.conditionFamily, WeatherConditionFamily.storm);
      expect(stormState.severeIntensity, greaterThanOrEqualTo(0.6));
      expect(stormState.cloudIntensity, equals(1.0));
      expect(stormState.storyLine, contains('thunderstorm'));
    });

    test('snow derives cold character and active snowfall storytelling', () {
      final snowState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.snow,
        now: DateTime(2026, 8, 29, 10, 0),
      );

      expect(snowState.conditionFamily, WeatherConditionFamily.snow);
      expect(snowState.temperatureCharacter, lessThan(0.0));
      expect(snowState.storyLine, contains('snowfall'));
    });

    test('fog reduces visibility factor and generates fog storytelling', () {
      final fogState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.fog,
        now: DateTime(2026, 8, 29, 8, 0),
      );

      expect(fogState.conditionFamily, WeatherConditionFamily.fog);
      expect(fogState.visibilityFactor, lessThan(0.1));
      expect(fogState.storyLine, contains('fog'));
    });

    test('windy weather derives wind family with directional parameters', () {
      final windState = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.windy,
        now: DateTime(2026, 8, 29, 15, 0),
      );

      expect(windState.conditionFamily, WeatherConditionFamily.wind);
      expect(windState.windIntensity, greaterThan(0.5));
      expect(windState.windDirection, equals(270.0));
      expect(windState.storyLine.toLowerCase(), contains('wind'));
    });
  });

  group('Solar Transitions & DaylightPhase Parsing', () {
    test('dawn phase activates within sunrise transition window', () {
      final state = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.dawn,
        now: DateTime(2026, 8, 29, 6, 25), // Sunrise is 6:30 AM
      );

      expect(state.daylightPhase, DaylightPhase.dawn);
      expect(state.storyLine, contains('Dawn'));
    });

    test('sunset / dusk phase activates within sunset transition window', () {
      final state = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.dusk,
        now: DateTime(2026, 8, 29, 19, 50), // Sunset is 8:00 PM
      );

      expect(state.daylightPhase, DaylightPhase.sunset);
      expect(state.storyLine, contains('Golden hour'));
    });

    test('night phase activates after sunset window closes', () {
      final state = WeatherAtmosphereState.fromWeather(
        ConditionFixtures.clearNight,
        now: DateTime(2026, 8, 29, 22, 0), // Sunset is 7:45 PM
      );

      expect(state.daylightPhase, DaylightPhase.night);
    });
  });

  group('WeatherAtmosphere & CurrentConditionsHero Widgets', () {
    testWidgets('WeatherAtmosphere renders across representative condition fixtures', (
      WidgetTester tester,
    ) async {
      final fixtures = [
        ConditionFixtures.clearDay,
        ConditionFixtures.clearNight,
        ConditionFixtures.partlyCloudyDay,
        ConditionFixtures.overcast,
        ConditionFixtures.lightRain,
        ConditionFixtures.heavyRain,
        ConditionFixtures.thunderstorm,
        ConditionFixtures.snow,
        ConditionFixtures.fog,
        ConditionFixtures.windy,
        ConditionFixtures.dawn,
        ConditionFixtures.dusk,
      ];

      for (final fixture in fixtures) {
        final state = WeatherAtmosphereState.fromWeather(
          fixture,
          now: DateTime(2026, 8, 29, 12),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: WeatherTheme.dark,
            home: SizedBox(
              width: 390,
              height: 844,
              child: WeatherAtmosphere(
                condition: fixture.condition,
                atmosphereState: state,
                animationProgress: 0.32,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(WeatherAtmosphere), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('CurrentConditionsHero displays condition storyLine and metrics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WeatherTheme.dark,
          home: Scaffold(
            body: CurrentConditionsHero(
              weather: ConditionFixtures.thunderstorm,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('48°'), findsOneWidget);
      expect(find.text('Storm'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
      expect(find.textContaining('thunderstorm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
