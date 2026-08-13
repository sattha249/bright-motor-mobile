import 'dart:convert';
import 'package:brightmotor_store/database/daos/truck_stock_dao.dart';
import 'package:brightmotor_store/models/truck_stock_model.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  final SessionPreferences preferences = SessionPreferences();
  final TruckStockDao _truckStockDao = TruckStockDao();
  
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  @override
  Future<Map<String, dynamic>> getStocks({
    required int truckId,
    required String query,
    int page = 1,
  }) async {
    try {
      final token = await preferences.getToken();
      
      String url = '$baseUrl/trucks/$truckId/stocks?page=$page&perPage=10';
      if (query.isNotEmpty) {
        url += '&search=$query';
      }

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final List<TruckStockItem> stocks = (data['data'] as List)
            .map((json) => TruckStockItem.fromJson(json))
            .toList();

        // Also cache online truck stock into local SQLite
        await _truckStockDao.saveTruckStocksBatch(truckId, stocks);

        return {
          'stocks': stocks,
          'meta': data['meta'],
        };
      }
    } catch (e) {
      debugPrint('Online truck stock fetch failed, falling back to SQLite: $e');
    }

    // --- Fallback: Read from Local SQLite DB ---
    final localStocks = await _truckStockDao.getTruckStocks(truckId);
    final filteredStocks = query.isEmpty
        ? localStocks
        : localStocks
            .where((item) =>
                item.product.description
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                item.product.productCode
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();

    return {
      'stocks': filteredStocks,
      'meta': {
        'total': filteredStocks.length,
        'per_page': filteredStocks.isNotEmpty ? filteredStocks.length : 10,
        'current_page': 1,
        'last_page': 1,
      },
    };
  }
}