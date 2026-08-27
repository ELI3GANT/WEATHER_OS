import 'location_service.dart';

class MockLocationService implements LocationService {
  const MockLocationService({
    this.mockResult = (
      latitude: 40.7128,
      longitude: -74.0060,
      locationName: 'New York',
    ),
  });

  final LocationResult? mockResult;

  @override
  Future<LocationResult?> getCurrentLocation() async => mockResult;
}
