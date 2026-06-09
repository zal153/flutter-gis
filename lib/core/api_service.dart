import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/posyandu_model.dart';

class ApiService {
  static const String baseUrl = 'https://3203-140-213-118-225.ngrok-free.app/api';
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<List<PosyanduModel>> fetchPosyandus({String search = ''}) async {
    try {
      final url = Uri.parse('$baseUrl/v1/posyandu?search=$search');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => PosyanduModel.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat data Posyandu. Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal koneksi ke server: $e');
    }
  }

  static Future<List<RouteModel>> fetchRoute(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      final url = Uri.parse(
          '$baseUrl/route?startLat=$startLat&startLng=$startLng&endLat=$endLat&endLng=$endLng');
      final response = await http.get(url);

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode == 200 &&
          body['success'] == true &&
          body['routes'] != null &&
          (body['routes'] as List).isNotEmpty) {
        final List<dynamic> routesJson = body['routes'];
        
        final List<RouteModel> allRoutes = routesJson.map((routeJson) {
          final List<dynamic> pathJson = routeJson['path'] ?? [];
          final double distance = double.tryParse(routeJson['distance'].toString()) ?? 0.0;
          
          final List<LatLng> coords = pathJson.map((point) {
            return LatLng(
              double.parse(point['lat'].toString()),
              double.parse(point['lng'].toString()),
            );
          }).toList();
          
          // Prepend start and append end coordinates to bridge the road gaps
          final List<LatLng> finalCoords = [];
          finalCoords.add(LatLng(startLat, startLng));
          finalCoords.addAll(coords);
          finalCoords.add(LatLng(endLat, endLng));
          
          return RouteModel(
            path: finalCoords,
            distance: distance,
            roadPath: coords,
          );
        }).toList();

        // Filter out highly similar alternative routes (overlap >= 50%)
        final List<RouteModel> filteredRoutes = [];
        if (allRoutes.isNotEmpty) {
          filteredRoutes.add(allRoutes[0]); // Always keep the main route

          for (int k = 1; k < allRoutes.length; k++) {
            final altRoute = allRoutes[k];
            final altRoad = altRoute.roadPath;
            if (altRoad == null || altRoad.isEmpty) {
              filteredRoutes.add(altRoute);
              continue;
            }

            final altKeys = altRoad.map((p) => '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}').toList();
            bool isDuplicate = false;

            for (final acceptedRoute in filteredRoutes) {
              final acceptedRoad = acceptedRoute.roadPath;
              if (acceptedRoad == null || acceptedRoad.isEmpty) {
                continue;
              }

              final acceptedKeys = acceptedRoad.map((p) => '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}').toSet();
              int sharedCount = 0;
              for (final key in altKeys) {
                if (acceptedKeys.contains(key)) {
                  sharedCount++;
                }
              }

              final double overlapRatio = sharedCount / altKeys.length;
              if (overlapRatio >= 0.50) {
                isDuplicate = true;
                break;
              }
            }

            if (!isDuplicate) {
              filteredRoutes.add(altRoute);
            }
          }
        }

        return filteredRoutes;
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
