import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product_model.dart';
import 'session_preferences.dart';

final productServiceProvider = Provider.autoDispose<ProductService>((ref) {
  return ProductServiceImpl();
});

abstract class ProductService {
  Future<ProductResponse> getProducts({String? category});

}


class MockProductService extends ProductService {
  @override
  Future<ProductResponse> getProducts({String? category}) async {
    return ProductResponse(
      meta: Meta(
        total: 10,
        perPage: 10,
        currentPage: 1,
        lastPage: 1,
        firstPage: 1,
        firstPageUrl: 'http://localhost:3333/products?category=category',
        lastPageUrl: 'http://localhost:3333/products?category=category',
        nextPageUrl: null,
        previousPageUrl: null,
      ),
      data: [
        Product(
          id: 1,
          category: 'category',
          description: 'Product Description',
          brand: 'brand',
          model: 'model',
          costPrice: '100',
          sellPrice: '200',
          unit: 'unit',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
    );
  }

}

class ProductServiceImpl extends ProductService {
  final SessionPreferences _authService = SessionPreferences();
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3333';

  @override
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

} 