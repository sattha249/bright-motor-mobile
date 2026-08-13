import 'dart:convert';
import 'dart:io';
import 'package:brightmotor_store/database/daos/customer_dao.dart';
import 'package:brightmotor_store/database/daos/pre_order_dao.dart';
import 'package:brightmotor_store/database/daos/sell_log_dao.dart';
import 'package:brightmotor_store/database/daos/truck_stock_dao.dart';
import 'package:brightmotor_store/database/daos/user_dao.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/models/pre_order_model.dart';
import 'package:brightmotor_store/models/truck_stock_model.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final syncServiceProvider = Provider.autoDispose<SyncService>((ref) {
  return SyncServiceImpl();
});

abstract class SyncService {
  Future<bool> syncData(int truckId);
}

class SyncServiceImpl implements SyncService {
  final SessionPreferences preferences = SessionPreferences();
  final CustomerDao _customerDao = CustomerDao();
  final TruckStockDao _truckStockDao = TruckStockDao();
  final PreOrderDao _preOrderDao = PreOrderDao();
  final SellLogDao _sellLogDao = SellLogDao();
  final UserDao _userDao = UserDao();

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  Future<String> _getQrCodePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/receipt_qrcode.png';
  }

  @override
  Future<bool> syncData(int truckId) async {
    try {
      // 1. Check Server Health
      final isServerOnline = await _checkServerHealth();
      if (!isServerOnline) return false;

      final token = await preferences.getToken();
      if (token == null || token.isEmpty) return false;

      // 2. Sync Master Customers
      await _syncCustomers(token);

      // 3. Sync Truck Stocks & Product Catalog (for THIS truck)
      await _syncTruckStock(token, truckId);

      // 4. Sync PreOrders (for THIS truck)
      await _syncPreOrders(token, truckId);

      // 5. Sync Sell Logs / Sales History (for THIS truck)
      await _syncSellLogs(token, truckId);

      // 6. Sync User Profile & Truck Info
      await _syncUserProfile(token);

      // 7. Sync QR Code Image
      await _syncQrCodeImage(token);

      return true;
    } catch (e) {
      debugPrint('Sync engine error: $e');
      return false;
    }
  }

  Future<bool> _checkServerHealth() async {
    try {
      final url = '$baseUrl/health-check';
      final response = await defaultHttpClient()
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _syncCustomers(String token) async {
    try {
      final url = '$baseUrl/customers?limit=1000';
      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List jsonList = data['data'] ?? [];
        final customers = jsonList.map((j) => Customer.fromJson(j)).toList();
        await _customerDao.insertOrUpdateBatch(customers);
      }
    } catch (e) {
      debugPrint('Error syncing customers: $e');
    }
  }

  Future<void> _syncTruckStock(String token, int truckId) async {
    try {
      final url = '$baseUrl/trucks/$truckId/stocks?perPage=1000';
      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List jsonList = data['data'] ?? [];
        final items =
            jsonList.map((j) => TruckStockItem.fromJson(j)).toList();
        await _truckStockDao.saveTruckStocksBatch(truckId, items);
      }
    } catch (e) {
      debugPrint('Error syncing truck stocks: $e');
    }
  }

  Future<void> _syncPreOrders(String token, int truckId) async {
    try {
      final url = '$baseUrl/pre-orders?truckId=$truckId&limit=1000';
      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List jsonList = data['data'] ?? [];
        final orders = jsonList.map((j) => PreOrder.fromJson(j)).toList();
        await _preOrderDao.upsertServerPreOrdersBatch(orders);
      }
    } catch (e) {
      debugPrint('Error syncing preorders: $e');
    }
  }

  Future<void> _syncSellLogs(String token, int truckId) async {
    try {
      final url = '$baseUrl/sell-logs?truck_id=$truckId&limit=1000';
      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List jsonList = data['data'] ?? [];
        final List<Map<String, dynamic>> rawLogs =
            jsonList.map((j) => Map<String, dynamic>.from(j)).toList();
        await _sellLogDao.upsertServerSellLogsBatch(rawLogs);
      }
    } catch (e) {
      debugPrint('Error syncing sell logs: $e');
    }
  }

  Future<void> _syncUserProfile(String token) async {
    try {
      final url = '$baseUrl/profile';
      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userMap = data['user'] ?? data;
        final truckMap = data['truck'] ?? {};

        final user = LocalUser(
          id: userMap['id'] ?? 0,
          username: userMap['username'] ?? '',
          email: userMap['email'],
          fullname: userMap['fullname'],
          tel: userMap['tel'],
          role: userMap['role'],
          truckId: truckMap['id'],
          truckName: truckMap['plate_number'],
          plateNumber: truckMap['plate_number'],
          plateProvince: truckMap['plate_province'],
        );

        await _userDao.saveUser(user);
      }
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
    }
  }

  Future<bool> _syncQrCodeImage(String token) async {
    try {
      final url = '$baseUrl/settings/qrcode';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final path = await _getQrCodePath();
        final file = File(path);
        await file.writeAsBytes(imageBytes);
        return true;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}