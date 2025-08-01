import 'dart:convert';

import 'package:brightmotor_store/main.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/providers/product_provider.dart';
import 'package:brightmotor_store/services/sell_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/product_model.dart';
import 'session_preferences.dart';

final productServiceProvider = Provider.autoDispose<ProductService>((ref) {
  final truckId = ref.watch(currentTruckIdProvider);
  final endpoint =  ref.watch(baseUrlProvider);
  final preferences = ref.watch(sessionPreferenceProvider);
  return ProductServiceImpl(
    authService: preferences,
    baseUrl: endpoint,
    truckId: truckId,
  );
});

abstract class ProductService {
  Future<ProductResponse> getProducts({String? category});

  Future<ProductResponse> search(String query);

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
  Future<ProductResponse> getProducts({String? category}) async {
    try {
      final headers = await authService.getAuthHeader();
      final url = category != null 
          ? '$baseUrl/products?category=$category'
          : '$baseUrl/products';

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
  Future<ProductResponse> search(String query) async {
    try {
      final headers = await authService.getAuthHeader();
      //FIXME: add truck_id to scope the search to a specific truck
      final url = '$baseUrl/products?search=$query';

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
}