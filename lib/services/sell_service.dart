

import 'dart:convert';

import 'package:brightmotor_store/main.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

final baseUrlProvider = Provider<String>((ref) {
  final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3333';
  return baseUrl;
});

final sellServiceProvider = Provider<SellService>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final preferences = ref.watch(sessionPreferenceProvider);
  return SellService(baseUrl, preferences);
});

class SellService {

  final String baseUrl;
  final SessionPreferences preferences;


  SellService(this.baseUrl, this.preferences);

  Future<void> sellLog(int truckId, int customerId, bool isCredit, Map<Product, int> items) async {
    final itemsJson = <Map>[];
    for (var item in items.entries) {
      itemsJson.add({
        'product_id': item.key.id,
        'quantity': item.value,
        'price': item.key.sellPrice
      });
    }
    final body = {
      'truck_id': truckId,
      'customer_id': customerId,
      'is_credit': null,
      'items': itemsJson,
    };

    final token = await preferences.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/sell-logs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      print('Sell log submitted successfully');
    } else {
      //log json error
      throw Exception('Failed to sell log');
    }
  }

}