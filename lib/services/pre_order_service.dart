import 'dart:convert';
import 'package:brightmotor_store/database/daos/pre_order_dao.dart';
import 'package:brightmotor_store/models/pre_order_model.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/foundation.dart';
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
  final PreOrderDao _preOrderDao = PreOrderDao();

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
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<PreOrder> list = (data['data'] as List)
            .map((e) => PreOrder.fromJson(e))
            .toList();

        // Also cache server preorders into SQLite
        await _preOrderDao.upsertServerPreOrdersBatch(list);

        return {
          'data': list,
          'meta': data['meta'],
        };
      }
    } catch (e) {
      debugPrint('Online pre-order fetch failed, falling back to SQLite: $e');
    }

    // --- Fallback: Read from Local SQLite DB ---
    final pendingOrders = await _preOrderDao.getPendingSyncPreOrders();
    final localList = pendingOrders.map((map) {
      return PreOrder(
        id: map['id'] ?? map['local_id'],
        billNo: map['bill_no'] ?? '-',
        status: map['status'] ?? 'Pending',
        totalSoldPrice: (map['total_sold_price'] as num?)?.toStringAsFixed(2) ?? '0.00',
        isCredit: map['is_credit'] ?? 'cash',
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : DateTime.now(),
        customer: POCustomer(name: 'ลูกค้า (ออฟไลน์)', tel: '-'),
      );
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
  Future<PreOrder> getPreOrderDetail(int id) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/pre-orders/$id';

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PreOrder.fromJson(data);
      }
      throw Exception('Failed to load pre-order detail');
    } catch (e) {
      throw Exception('Error loading detail: $e');
    }
  }

  @override
  Future<void> confirmPreOrder(int id) async {
    final token = await preferences.getToken();
    final url = '$baseUrl/pre-orders/$id/confirm';

    final response = await defaultHttpClient().put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to confirm pre-order');
    }
  }

  @override
  Future<Map<String, dynamic>> getPreOrderRaw(int id) async {
    final token = await preferences.getToken();
    final url = '$baseUrl/pre-orders/$id';

    final response = await defaultHttpClient().get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load raw pre-order detail');
    }
  }

  @override
  Future<void> cancelPreOrder(int preOrderId) async {
    final token = await preferences.getToken();
    final url = '$baseUrl/pre-orders/$preOrderId/cancel';

    final response = await defaultHttpClient().put(
      Uri.parse(url),
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