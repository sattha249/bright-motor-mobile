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

  // [แก้ไข] เพิ่ม page และ limit (default ไว้ที่ 20)
  Future<TruckResponse> getTruckStocks(int truckId, {int page = 1, int limit = 20}) async {
    try {
      final token = await preferences.getToken();

      // [แก้ไข] ส่ง Query Param page และ limit ไปแทน hardcode perPage=50
      final url = "$endpoint/trucks/$truckId/stocks?page=$page&limit=$limit";

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Truck stocks response: ${response.body}');
        return TruckResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      print('Error fetching truck stocks: $e');
      throw Exception('Error fetching products: $e');
    }
  }
}