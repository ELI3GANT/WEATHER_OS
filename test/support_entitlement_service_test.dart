import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/features/weather/services/support_entitlement_service.dart';

void main() {
  group('WeatherSupportTier', () {
    test('uses stable Play product identifiers', () {
      expect(
        WeatherSupportTier.values
            .map((WeatherSupportTier tier) => tier.productId)
            .whereType<String>(),
        <String>[
          'weatheros_coffee_unlock',
          'weatheros_supercharge_unlock',
          'weatheros_patron_unlock',
        ],
      );
      expect(
        WeatherSupportTier.values
            .map((WeatherSupportTier tier) => tier.tipProductId)
            .whereType<String>(),
        <String>[
          'weatheros_coffee_tip',
          'weatheros_supercharge_tip',
          'weatheros_patron_tip',
        ],
      );
    });

    test('higher permanent tiers include lower tiers', () {
      expect(
        WeatherSupportTier.coffee.includes(WeatherSupportTier.coffee),
        isTrue,
      );
      expect(
        WeatherSupportTier.supercharge.includes(WeatherSupportTier.coffee),
        isTrue,
      );
      expect(
        WeatherSupportTier.patron.includes(WeatherSupportTier.supercharge),
        isTrue,
      );
      expect(
        WeatherSupportTier.coffee.includes(WeatherSupportTier.patron),
        isFalse,
      );
    });

    test('maps unlock and tip products back to their tier', () {
      expect(
        WeatherSupportTier.fromProductId('weatheros_supercharge_unlock'),
        WeatherSupportTier.supercharge,
      );
      expect(
        WeatherSupportTier.fromProductId('weatheros_patron_tip'),
        WeatherSupportTier.patron,
      );
      expect(
        WeatherSupportTier.isTipProduct('weatheros_coffee_tip'),
        isTrue,
      );
      expect(
        WeatherSupportTier.fromProductId('unknown_product'),
        WeatherSupportTier.none,
      );
    });
  });
}
