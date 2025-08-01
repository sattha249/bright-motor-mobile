
import 'dart:convert';

import 'package:brightmotor_store/main.dart';
import 'package:brightmotor_store/models/truck_info.dart';
import 'package:brightmotor_store/models/truck_response.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:hooks_riverpod/hooks_riverpod.dart';

final truckServiceProvider = Provider.autoDispose<TruckService>((ref) {
  final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3333';
  return TruckService(baseUrl, ref.read(sessionPreferenceProvider));
});

class TruckService {

  final String endpoint;
  final SessionPreferences preferences;

  TruckService(this.endpoint, this.preferences);

  Future<TruckInfo> getTruckInfo() async {
    final token = await preferences.getToken();
    final response = await defaultHttpClient().get(
      Uri.parse('$endpoint/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final body = TruckInfo.fromJson(data);
      return body;
    } else {
      throw Exception('Failed to load trucks');
    }
  }

  Future<TruckResponse> getTruckStocks(int truckId) async {
    try {
      final token = await preferences.getToken();


      final response = await defaultHttpClient().get(
        Uri.parse("$endpoint/trucks/$truckId/stocks?perPage=50"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return TruckResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }


}