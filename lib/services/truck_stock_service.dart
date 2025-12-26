import 'dart:convert';
import 'package:brightmotor_store/models/truck_stock_model.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ไม่ต้อง watch sessionPreferenceProvider แล้ว สร้าง Service ขึ้นมาตรงๆ เลย
final truckStockServiceProvider = Provider.autoDispose<TruckStockService>((ref) {
  return TruckStockServiceImpl();
});

abstract class TruckStockService {
  Future<Map<String, dynamic>> getStocks({
    required int truckId,
    required String query,
    int page = 1,
  });
}

class TruckStockServiceImpl implements TruckStockService {
  // [แก้ไข] สร้าง Instance เองตรงนี้ ตาม Pattern หน้า Customer
  final SessionPreferences preferences = SessionPreferences();
  
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  @override
  Future<Map<String, dynamic>> getStocks({
    required int truckId,
    required String query,
    int page = 1,
  }) async {
    try {
      final token = await preferences.getToken();
      
      String url = '$baseUrl/trucks/$truckId/stocks?page=$page&limit=10';
      if (query.isNotEmpty) {
        url += '&search=$query';
      }

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final List<TruckStockItem> stocks = (data['data'] as List)
            .map((json) => TruckStockItem.fromJson(json))
            .toList();

        return {
          'stocks': stocks,
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load stocks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stocks: $e');
    }
  }
}