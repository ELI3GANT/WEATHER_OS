import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

class RainViewerRadarService {
  const RainViewerRadarService({this.client});
  final http.Client? client;

  Future<String?> latestTileUrl({required double latitude, required double longitude}) async {
    final c = client ?? http.Client();
    try {
      final response = await c.get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json')).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final host = decoded['host'];
      final radar = decoded['radar'];
      final past = radar is Map<String, dynamic> ? radar['past'] : null;
      if (host is! String || past is! List || past.isEmpty) return null;
      final frame = past.last;
      final path = frame is Map<String, dynamic> ? frame['path'] : null;
      if (path is! String) return null;
      const zoom = 5;
      final n = 1 << zoom;
      final x = (((longitude + 180) / 360) * n).floor().clamp(0, n - 1);
      final latRad = latitude * math.pi / 180;
      final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor().clamp(0, n - 1);
      return '$host$path/256/$zoom/$x/$y/2/1_1.png';
    } on Object {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
