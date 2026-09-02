import 'dart:convert';

import 'package:http/http.dart' as http;

import 'location_service.dart';

class LocationSearchService {
  const LocationSearchService({this.client});

  final http.Client? client;

  Future<LocationResult?> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final httpClient = client ?? http.Client();
    final closeClient = client == null;
    try {
      final uri = Uri.parse('https://geocoding-api.open-meteo.com/v1/search')
          .replace(queryParameters: <String, String>{
        'name': trimmed,
        'count': '1',
        'language': 'en',
        'format': 'json',
      });
      final response = await httpClient.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final results = decoded is Map<String, dynamic>
          ? decoded['results']
          : null;
      if (results is! List || results.isEmpty || results.first is! Map) return null;
      final result = results.first as Map;
      final latitude = (result['latitude'] as num?)?.toDouble();
      final longitude = (result['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;
      final name = (result['name'] as String?)?.trim() ?? trimmed;
      final admin = (result['admin1'] as String?)?.trim();
      final country = (result['country_code'] as String?)?.trim();
      final suffix = admin?.isNotEmpty == true ? admin : country;
      return (
        latitude: latitude,
        longitude: longitude,
        locationName: suffix?.isNotEmpty == true ? '$name, $suffix' : name,
      );
    } on Object {
      return null;
    } finally {
      if (closeClient) httpClient.close();
    }
  }
}
