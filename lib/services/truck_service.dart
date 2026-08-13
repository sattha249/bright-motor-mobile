import 'dart:convert';
import 'package:brightmotor_store/database/daos/truck_stock_dao.dart';
import 'package:brightmotor_store/database/daos/user_dao.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/models/truck_info.dart';
import 'package:brightmotor_store/models/truck_response.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final truckServiceProvider = Provider.autoDispose<TruckService>((ref) {
  final baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';
  return TruckService(baseUrl, SessionPreferences());
});

class TruckService {
  final String endpoint;
  final SessionPreferences preferences;
  final TruckStockDao _truckStockDao = TruckStockDao();
  final UserDao _userDao = UserDao();

  TruckService(this.endpoint, this.preferences);

  Future<TruckInfo> getTruckInfo() async {
    try {
      final token = await preferences.getToken();
      final response = await defaultHttpClient().get(
        Uri.parse('$endpoint/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final body = TruckInfo.fromJson(data);

        final userMap = data['user'] ?? data;
        final truckMap = data['truck'] ?? {};

        final user = LocalUser(
          id: userMap['id'] ?? 0,
          username: userMap['username'] ?? '',
          email: userMap['email'],
          fullname: userMap['fullname'],
          tel: userMap['tel'],
          role: userMap['role'],
          truckId: truckMap['id'] ?? body.truckId,
          truckName: truckMap['plate_number'] ?? body.fullName,
          plateNumber: truckMap['plate_number'],
          plateProvince: truckMap['plate_province'],
        );

        await _userDao.saveUser(user);
        return body;
      }
    } catch (e) {
      debugPrint('Truck profile fetch error, falling back to SQLite: $e');
    }

    // --- Fallback: Read Active User & Truck ID from SQLite DB ---
    final localUser = await _userDao.getActiveUser();
    if (localUser != null) {
      return TruckInfo(
        localUser.id,
        localUser.truckId,
        localUser.username,
        localUser.email,
        localUser.fullname,
        localUser.tel,
        localUser.role,
      );
    }

    return TruckInfo(0, 0, 'offline', '', 'ออฟไลน์', '', 'truck');
  }

  Future<TruckResponse> getTruckStocks(int truckId, {int page = 1, int limit = 20}) async {
    int effectiveTruckId = truckId;
    if (effectiveTruckId <= 0) {
      final localUser = await _userDao.getActiveUser();
      effectiveTruckId = localUser?.truckId ?? 0;
    }

    try {
      final token = await preferences.getToken();
      final url = "$endpoint/trucks/$effectiveTruckId/stocks?page=$page&perPage=$limit";

      final response = await defaultHttpClient().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return TruckResponse.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Online truck stock load failed, falling back to SQLite: $e');
    }

    // --- Fallback: Read from Local SQLite DB ---
    final localItems = await _truckStockDao.getTruckStocks(effectiveTruckId);
    final truckList = localItems.map((item) {
      final p = item.product;
      return Truck(
        id: item.id,
        truckId: item.truckId,
        productId: p.id,
        quantity: item.quantity,
        product: Product(
          id: p.id,
          category: 'ทั่วไป',
          description: p.description,
          brand: '',
          model: '',
          costPrice: '0',
          sellPrice: p.sellPrice,
          unit: p.unit,
          quantity: item.quantity,
        ),
      );
    }).toList();

    return TruckResponse(data: truckList);
  }
}