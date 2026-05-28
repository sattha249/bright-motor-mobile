import 'dart:convert';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // อย่าลืม import dotenv
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

// 1. สร้าง Interface
abstract class SellHistoryService {
  Future<Map<String, dynamic>> getSellLogs({required int truckId, int page = 1});
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
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 2. [แก้ไข] Return ข้อมูลทั้งก้อน เพื่อให้ UI เข้าถึง key 'meta' ได้
        if (data is Map<String, dynamic>) {
          // กรณี API มาตามมาตรฐาน: { "data": [...], "meta": {...} }
          return data; 
        } else if (data is List) {
          // กรณี API ส่งมาแค่ List เพียวๆ (กันเหนียวไว้ก่อน)
          // เราต้องห่อมันเพื่อให้หน้า UI ไม่พังเมื่อพยายามเข้าถึง ['meta']
          return {
            'data': data,
            'meta': {
              'current_page': 1,
              'last_page': 1,
              'total': data.length
            }
          };
        }
        
        return {'data': [], 'meta': {}};
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
      // 1. ดึงส่วนลด และ ราคาสุทธิ จาก API (รองรับทั้ง snake_case และ camelCase)
      final discountFromApi = double.tryParse(item['discount']?.toString() ?? '') ?? 
                             double.tryParse(item['discountValue']?.toString() ?? '') ?? 0.0;
      final soldPriceFromApi = double.tryParse(item['sold_price']?.toString() ?? '') ?? 
                              double.tryParse(item['soldPrice']?.toString() ?? '') ?? 0.0;
      final priceFromApi = double.tryParse(item['price']?.toString() ?? '') ?? 0.0;

      // 2. ป้องกัน Bug การลดราคาสองเด้ง (Double Discount)
      // โดยปกติ 'price' คือราคาเต็ม และ 'sold_price' คือราคาหลังลด
      // แต่กรณีที่ 'price' ถูกบันทึกเป็นราคาที่ลดแล้ว (price == sold_price) เราจะกู้ราคาเต็มกลับมา
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

      return CartItem(
        product: product,
        quantity: int.tryParse(item['quantity'].toString()) ?? 1,
        discountValue: discountFromApi, 
      );
    }).toList();
  }
}