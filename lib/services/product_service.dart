import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product_model.dart';
import 'auth_service.dart';

class ProductService {
  final AuthService _authService = AuthService();
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3333';

  Future<ProductResponse> getProducts({String? category}) async {
    try {
      final headers = await _authService.getAuthHeader();
      final url = category != null 
          ? '$baseUrl/products?category=$category'
          : '$baseUrl/products';

      final response = await http.get(
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

  Future<Map<String, int>> getCategoryCounts() async {
    try {
      final products = await getProducts();
      final categoryCounts = <String, int>{};
      
      for (var product in products.data) {
        categoryCounts[product.category] = (categoryCounts[product.category] ?? 0) + 1;
      }
      
      return categoryCounts;
    } catch (e) {
      throw Exception('Error getting category counts: $e');
    }
  }
} 