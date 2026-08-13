import 'dart:convert';
import 'package:brightmotor_store/database/daos/sell_log_dao.dart';
import 'package:brightmotor_store/database/daos/user_dao.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

final sellServiceProvider = Provider.autoDispose<SellService>((ref) {
  return SellServiceImpl();
});

abstract class SellService {
  Future<String> submitOrder({
    required int truckId,
    required int customerId,
    required PaymentTerm paymentTerm,
    required List<CartItem> items,
  });
  Future<void> createSellLogFromPreOrder(Map<String, dynamic> payload);
}

class SellServiceImpl implements SellService {
  final SessionPreferences preferences = SessionPreferences();
  final SellLogDao _sellLogDao = SellLogDao();
  final UserDao _userDao = UserDao();

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  SellServiceImpl();

  @override
  Future<String> submitOrder({
    required int truckId,
    required int customerId,
    required PaymentTerm paymentTerm,
    required List<CartItem> items,
  }) async {
    String? isCreditValue;
    switch (paymentTerm) {
      case PaymentTerm.weekly:
        isCreditValue = 'week';
        break;
      case PaymentTerm.monthly:
        isCreditValue = 'month';
        break;
      case PaymentTerm.cash:
        isCreditValue = 'cash';
        break;
    }

    double totalPrice = 0.0;
    double totalDiscount = 0.0;
    double totalSoldPrice = 0.0;

    final localItems = <LocalSellLogItem>[];
    final itemsJson = items.map((item) {
      final itemTotalPrice = item.price * item.quantity;
      totalPrice += itemTotalPrice;
      totalDiscount += item.totalDiscount;
      totalSoldPrice += item.totalSoldPrice;

      bool finalIsPaid = (paymentTerm == PaymentTerm.cash) ? true : item.isPaid;

      localItems.add(LocalSellLogItem(
        productId: item.product.id,
        quantity: item.quantity.toDouble(),
        price: item.price,
        totalPrice: itemTotalPrice,
        discount: item.discountAmount,
        soldPrice: item.soldPrice,
        isPaid: finalIsPaid,
      ));

      return {
        "productId": item.product.id,
        "quantity": item.quantity,
        "price": item.price,
        "discount": item.discountAmount.toStringAsFixed(2),
        "sold_price": item.soldPrice.toStringAsFixed(2),
        "is_paid": finalIsPaid
      };
    }).toList();

    final user = await _userDao.getActiveUser();
    final userId = user?.id ?? 0;
    final uuid = const Uuid().v4();
    final offlineBillNo = 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Insert offline sale into SQLite staging table & deduct local truck stock immediately!
    final localSale = LocalSellLog(
      uuid: uuid,
      billNo: offlineBillNo,
      truckId: truckId,
      truckName: user?.truckName,
      customerId: customerId,
      userId: userId,
      totalPrice: totalPrice,
      totalDiscount: totalDiscount,
      totalSoldPrice: totalSoldPrice,
      isCredit: isCreditValue ?? 'cash',
      isPaid: paymentTerm == PaymentTerm.cash,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      items: localItems,
    );

    final localId = await _sellLogDao.insertOfflineSale(localSale);

    // 2. Try online API post
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/sell-logs';

      final body = {
        "uuid": uuid,
        "truckId": truckId,
        "customerId": customerId,
        "isCredit": isCreditValue == 'cash' ? null : isCreditValue,
        "totalDiscount": totalDiscount.toStringAsFixed(2),
        "totalSoldPrice": totalSoldPrice.toStringAsFixed(2),
        "items": itemsJson
      };

      final response = await defaultHttpClient().post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-Idempotency-Key': uuid,
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final serverBillNo = responseData['bill_no'] ??
            responseData['data']?['bill_no'] ??
            offlineBillNo;
        final serverId = responseData['id'] ?? responseData['data']?['id'];

        if (serverId != null) {
          await _sellLogDao.markSynced(localId, serverId as int);
        }
        return serverBillNo.toString();
      }
    } catch (e) {
      debugPrint('Online order submission failed, stored offline in SQLite: $e');
    }

    // Fallback: return offline bill number
    return offlineBillNo;
  }

  @override
  Future<void> createSellLogFromPreOrder(Map<String, dynamic> payload) async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/sell-logs';

      final response = await defaultHttpClient().post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create sell log: ${response.body}');
      }
    } catch (e) {
      debugPrint('PreOrder confirm sell log creation failed: $e');
    }
  }
}