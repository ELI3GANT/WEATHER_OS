import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'location_service.dart';

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({
    this.httpClient,
  });

  final http.Client? httpClient;

  @override
  Future<LocationResult?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } on Exception {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return null;
      }

      final locationName = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return (
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
      );
    } on Exception {
      return null;
    }
  }

  Future<String> _reverseGeocode(double latitude, double longitude) async {
    final client = httpClient ?? http.Client();
    final shouldClose = httpClient == null;

    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
      ).replace(
        queryParameters: <String, String>{
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'localityLanguage': 'en',
        },
      );

      final response = await client
          .get(uri, headers: const <String, String>{'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == HttpStatus.ok) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final city = (decoded['city'] as String?)?.trim();
          final locality = (decoded['locality'] as String?)?.trim();
          final stateCode = (decoded['principalSubdivisionCode'] as String?)?.trim();
          final stateName = (decoded['principalSubdivision'] as String?)?.trim();
          final countryCode = (decoded['countryCode'] as String?)?.trim();

          final resolvedCity = (city != null && city.isNotEmpty)
              ? city
              : ((locality != null && locality.isNotEmpty) ? locality : null);

          if (resolvedCity != null) {
            if (stateCode != null && stateCode.startsWith('US-')) {
              final state = stateCode.replaceFirst('US-', '');
              return '$resolvedCity, $state';
            }
            if (countryCode == 'US' && stateName != null && stateName.isNotEmpty) {
              return '$resolvedCity, $stateName';
            }
            if (countryCode != null && countryCode.isNotEmpty) {
              return '$resolvedCity, $countryCode';
            }
            return resolvedCity;
          }
        }
      }
    } on Exception {
      // Graceful fallback on network timeout or failure
    } finally {
      if (shouldClose) {
        client.close();
      }
    }

    return 'Current Location';
  }
}
