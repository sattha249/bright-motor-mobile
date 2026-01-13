import 'dart:convert';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // อย่าลืม import dotenv
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

// 1. สร้าง Interface
abstract class SellHistoryService {
  Future<List<dynamic>> getSellLogs({required int truckId});
  List<CartItem> convertLogToCartItems(List<dynamic> itemsData);
}

// 2. Provider เรียกใช้ Implementation
final sellHistoryServiceProvider = Provider<SellHistoryService>((ref) {
  return SellHistoryServiceImpl();
});

// ฟังก์ชันจำลอง defaultHttpClient (ถ้าในโปรเจคมีอยู่แล้วให้ใช้ของโปรเจค)
http.Client defaultHttpClient() => http.Client();

// 3. Implementation Class (Logic ที่คุณต้องการ)
class SellHistoryServiceImpl implements SellHistoryService {
  final SessionPreferences preferences = SessionPreferences();
  
  // ใช้ dotenv ตามแบบฉบับ
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  @override
  Future<List<dynamic>> getSellLogs({required int truckId}) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/sell-logs?truckId=$truckId';

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // รองรับทั้งแบบ return List ตรงๆ หรือ return { data: [...] }
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return data['data'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
        
        return [];
      } else {
        throw Exception('Failed to load sell logs: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Helper สำหรับแปลงข้อมูลไปพิมพ์ (Logic เดิมแต่ย้ายมาให้เป็นระเบียบ)
  @override
  List<CartItem> convertLogToCartItems(List<dynamic> itemsData) {
    print(itemsData);
    return itemsData.map((item) {
      final product = Product(
        id: item['product_id'] ?? 0,
        description: item['product']['description'] ?? 'สินค้า',
        
        category: item['product']['category'] ?? '',
        brand: item['brand'] ?? '',
        model: item['model'] ?? '',
        unit: item['unit'] ?? '',
        
        costPrice: (item['cost_price'] ?? '0').toString(),
        sellPrice: (item['price'] ?? '0').toString(),
        
        quantity: 0,
      );

      return CartItem(
        product: product,
        quantity: int.tryParse(item['quantity'].toString()) ?? 1,
      );
    }).toList();
  }
}