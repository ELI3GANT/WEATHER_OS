import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:weather_os/features/weather/services/rainviewer_radar_service.dart';

void main() {
  test('uses the latest RainViewer frame for valid map coordinates', () async {
    final client = _RadarClient(
      http.Response(
        jsonEncode(<String, dynamic>{
          'host': 'https://radar.example',
          'radar': <String, dynamic>{
            'past': <Map<String, String>>[
              <String, String>{'path': '/v1'},
              <String, String>{'path': '/v2'},
            ],
          },
        }),
        200,
      ),
    );

    final data = await RainViewerRadarService(client: client)
        .fetchRadarTiles(latitude: 40.7128, longitude: -74.0060, zoom: 7);

    expect(data, isNotNull);
    expect(data!.radarOverlayUrl, contains('https://radar.example/v2/256/7/'));
    expect(data.baseMapUrl, contains('/7/'));
  });

  test('rejects invalid coordinates before requesting radar data', () async {
    final client = _RadarClient(http.Response('{}', 200));

    final data = await RainViewerRadarService(client: client)
        .fetchRadarTiles(latitude: 90, longitude: 0);

    expect(data, isNull);
    expect(client.requestCount, 0);
  });

  test('returns unavailable state for malformed metadata', () async {
    final client = _RadarClient(http.Response('{"radar":{"past":[]}}', 200));

    final data = await RainViewerRadarService(client: client)
        .fetchRadarTiles(latitude: 40, longitude: -74);

    expect(data, isNull);
  });
}

class _RadarClient extends http.BaseClient {
  _RadarClient(this.response);

  final http.Response response;
  int requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
