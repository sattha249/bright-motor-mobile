import 'dart:convert';
import 'package:brightmotor_store/models/pre_order_model.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final preOrderServiceProvider = Provider.autoDispose<PreOrderService>((ref) {
  return PreOrderServiceImpl();
});

abstract class PreOrderService {
  Future<Map<String, dynamic>> getPreOrders({required int truckId, int page = 1});
  Future<PreOrder> getPreOrderDetail(int id);
  Future<void> confirmPreOrder(int id);
  Future<Map<String, dynamic>> getPreOrderRaw(int id);
  Future<void> cancelPreOrder(int preOrderId);
}

class PreOrderServiceImpl implements PreOrderService {
  final SessionPreferences preferences = SessionPreferences();
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  @override
  Future<Map<String, dynamic>> getPreOrders({required int truckId, int page = 1}) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/pre-orders?truckId=$truckId&page=$page&per_page=10';

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<PreOrder> list = (data['data'] as List)
            .map((e) => PreOrder.fromJson(e))
            .toList();

        return {
          'data': list,
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load pre-orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Future<PreOrder> getPreOrderDetail(int id) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/pre-orders/$id';

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // สมมติว่า API Detail return object เดียว ไม่ได้ห่อ data
        // ถ้าห่อ data ให้แก้เป็น PreOrder.fromJson(data['data'])
        return PreOrder.fromJson(data); 
      } else {
        throw Exception('Failed to load detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Future<void> confirmPreOrder(int id) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/pre-orders/$id/confirm';
      final response = await defaultHttpClient().post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to confirm: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error confirming: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPreOrderRaw(int id) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/pre-orders/$id';
      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load raw data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting raw data: $e');
    }
  }

  Future<void> cancelPreOrder(int preOrderId) async {
  final token = await preferences.getToken();
  // แก้ path ตาม API ของคุณ
  final response = await defaultHttpClient().post(
    Uri.parse('$baseUrl/pre-orders/$preOrderId/cancel'), 
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to cancel pre-order: ${response.body}');
  }
}
}