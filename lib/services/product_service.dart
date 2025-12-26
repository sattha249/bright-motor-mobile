import 'dart:convert';

import 'package:brightmotor_store/main.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/providers/product_provider.dart';
import 'package:brightmotor_store/services/sell_service.dart';
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';

import '../models/product_model.dart';
import '../models/product_search_response.dart';
import 'session_preferences.dart';

final productServiceProvider = Provider.autoDispose<ProductService>((ref) {
  final truckId = ref.watch(currentTruckIdProvider);
  final endpoint = ref.watch(baseUrlProvider);
  final preferences = ref.watch(sessionPreferenceProvider);
  return ProductServiceImpl(
    authService: preferences,
    baseUrl: endpoint,
    truckId: truckId,
  );
});

abstract class ProductService {
  // [แก้ไข] เพิ่ม page และ limit
  Future<ProductResponse> getProducts({String? category, int page = 1, int limit = 20});

  // [แก้ไข] เพิ่ม page และ limit
  Future<ProductResponse> search(String query, {int page = 1, int limit = 20});
}

class ProductServiceImpl extends ProductService {
  final SessionPreferences authService;
  final String baseUrl;
  final int? truckId;

  ProductServiceImpl({
    required this.authService,
    required this.baseUrl,
    this.truckId,
  }) : super();

  @override
  Future<ProductResponse> getProducts({String? category, int page = 1, int limit = 20}) async {
    try {
      final headers = await authService.getAuthHeader();
      
      // [แก้ไข] สร้าง URL พร้อม Pagination Query Params
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
      
      // [แก้ไข] เพิ่ม &page=$page&limit=$limit ต่อท้าย URL
      final url = '$baseUrl/trucks/$truckId/stocks?search=$query&page=$page&limit=$limit';

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = ProductSearchResponse.fromJson(jsonDecode(response.body));
        
        // Map ข้อมูลให้ตรงกับ Model Product
        final products = data.data.map((e) => e.product).whereNotNull().toList();
        final meta = data.meta;
        
        // ส่งกลับพร้อม Meta data (จำเป็นสำหรับเช็คว่ามีหน้าถัดไปไหม)
        return ProductResponse(meta: meta, data: products);
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }
}