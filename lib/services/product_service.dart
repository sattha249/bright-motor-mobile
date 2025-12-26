import 'dart:convert';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/models/product_search_response.dart'; // ถ้ามีไฟล์นี้
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/providers/product_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:collection/collection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final productServiceProvider = Provider.autoDispose<ProductService>((ref) {
  // [แก้ไข] รับแค่ truckId ก็พอ
  final truckId = ref.watch(currentTruckIdProvider);
  return ProductServiceImpl(truckId: truckId);
});

abstract class ProductService {
  Future<ProductResponse> getProducts({String? category, int page = 1, int limit = 20});
  Future<ProductResponse> search(String query, {int page = 1, int limit = 20});
}

class ProductServiceImpl extends ProductService {
  // [แก้ไข] สร้างเองตรงนี้
  final SessionPreferences authService = SessionPreferences();
  
  // [แก้ไข] อ่าน URL เอง
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';
  
  final int? truckId;

  ProductServiceImpl({
    this.truckId,
  }) : super();

  @override
  Future<ProductResponse> getProducts({String? category, int page = 1, int limit = 20}) async {
    try {
      final headers = await authService.getAuthHeader();
      
      String url = '$baseUrl/products?page=$page&limit=$limit';
      if (category != null && category != "ทั้งหมด") {
        url += '&category=$category';
      }

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return ProductResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  @override
  Future<ProductResponse> search(String query, {int page = 1, int limit = 20}) async {
    if (truckId == null) {
      throw Exception('Truck ID is not set. Cannot perform search.');
    }
    try {
      final headers = await authService.getAuthHeader();
      
      final url = '$baseUrl/trucks/$truckId/stocks?search=$query&page=$page&limit=$limit';

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // หมายเหตุ: ตรงนี้ถ้าโครงสร้าง JSON ของ search ไม่เหมือน getProducts ปกติ 
        // อาจจะต้องปรับแก้การ Parse ให้ตรงกับ API จริงของคุณ
        // แต่เบื้องต้นผมใช้ ProductResponse ตามที่คุณเคยให้มา
        return ProductResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }
}