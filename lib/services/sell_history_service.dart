import 'dart:convert';
import 'package:brightmotor_store/database/daos/sell_log_dao.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class SellHistoryService {
  Future<Map<String, dynamic>> getSellLogs({required int truckId, int page = 1});
  List<CartItem> convertLogToCartItems(List<dynamic> itemsData);
}

final sellHistoryServiceProvider = Provider<SellHistoryService>((ref) {
  return SellHistoryServiceImpl();
});

class SellHistoryServiceImpl implements SellHistoryService {
  final SessionPreferences preferences = SessionPreferences();
  final SellLogDao _sellLogDao = SellLogDao();

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  @override
  Future<Map<String, dynamic>> getSellLogs({required int truckId, int page = 1}) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/sell-logs?truck_id=$truckId&page=$page';

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          final rawLogs = (data['data'] as List?)
                  ?.map((j) => Map<String, dynamic>.from(j))
                  .toList() ??
              [];
          await _sellLogDao.upsertServerSellLogsBatch(rawLogs);
          return data;
        } else if (data is List) {
          final rawLogs =
              data.map((j) => Map<String, dynamic>.from(j)).toList();
          await _sellLogDao.upsertServerSellLogsBatch(rawLogs);
          return {
            'data': data,
            'meta': {'current_page': 1, 'last_page': 1, 'total': data.length}
          };
        }
      }
    } catch (e) {
      debugPrint('Online sell log fetch failed, falling back to SQLite: $e');
    }

    // --- Fallback: Read ALL Sales from Local SQLite DB ---
    final allLocalSales = await _sellLogDao.getAllSellLogs(truckId);
    final localList = allLocalSales.map((map) {
      return {
        'id': map['id'] ?? map['local_id'],
        'bill_no': map['bill_no'] ?? '-',
        'truck_id': map['truck_id'],
        'truck_name': map['truck_name'] ?? 'รถ (ออฟไลน์)',
        'total_price': map['total_price'] ?? 0.0,
        'total_sold_price': map['total_sold_price'] ?? map['total_price'],
        'total_discount': map['total_discount'] ?? 0.0,
        'is_credit': map['is_credit'] ?? 'cash',
        'is_paid': map['is_paid'] == 1,
        'created_at': map['created_at'] ?? DateTime.now().toIso8601String(),
        'customer': map['customer'] ?? {'name': 'ลูกค้าทั่วไป', 'tel': '-'},
        'items': map['items'] ?? [],
      };
    }).toList();

    return {
      'data': localList,
      'meta': {
        'total': localList.length,
        'per_page': localList.isNotEmpty ? localList.length : 10,
        'current_page': 1,
        'last_page': 1,
      },
    };
  }

  @override
  List<CartItem> convertLogToCartItems(List<dynamic> itemsData) {
    return itemsData.map((item) {
      final discountFromApi = double.tryParse(item['discount']?.toString() ?? '') ??
          double.tryParse(item['discountValue']?.toString() ?? '') ??
          0.0;
      final soldPriceFromApi = double.tryParse(item['sold_price']?.toString() ?? '') ??
          double.tryParse(item['soldPrice']?.toString() ?? '') ??
          0.0;
      final priceFromApi = double.tryParse(item['price']?.toString() ?? '') ?? 0.0;

      double finalSellPrice = priceFromApi;
      if (soldPriceFromApi > 0 && discountFromApi > 0) {
        if (priceFromApi <= 0 || (priceFromApi - soldPriceFromApi).abs() < 0.01) {
          finalSellPrice = soldPriceFromApi + discountFromApi;
        } else {
          finalSellPrice = priceFromApi;
        }
      } else if (soldPriceFromApi > 0) {
        finalSellPrice = priceFromApi > 0 ? priceFromApi : soldPriceFromApi;
      }

      final product = Product(
        id: item['product_id'] ?? 0,
        description: item['product']?['description'] ?? 'สินค้า',
        category: item['product']?['category'] ?? '',
        brand: item['brand'] ?? '',
        model: item['model'] ?? '',
        unit: item['unit'] ?? '',
        costPrice: (item['cost_price'] ?? '0').toString(),
        sellPrice: finalSellPrice.toString(),
        quantity: 0,
      );

      final qty = int.tryParse(item['quantity'].toString()) ?? 1;
      return CartItem(
        product: product,
        quantity: qty,
        discountValue: CartItem.reconstructDiscountValue(discountFromApi, qty),
      );
    }).toList();
  }
}