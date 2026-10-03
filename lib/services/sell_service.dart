import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sale_contract.dart';
import 'sale_receipt.dart';
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
  Future<SaleReceipt> createSellLogFromPreOrder(Map<String, dynamic> payload);
}

class SellServiceImpl implements SellService {
  final SessionPreferences preferences;
  final SellLogDao _sellLogDao;
  final UserDao _userDao;
  final http.Client _client;

  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  SellServiceImpl(
      {SessionPreferences? preferences,
      SellLogDao? sellLogDao,
      UserDao? userDao,
      http.Client? client})
      : preferences = preferences ?? SessionPreferences(),
        _sellLogDao = sellLogDao ?? SellLogDao(),
        _userDao = userDao ?? UserDao(),
        _client = client ?? defaultHttpClient();

  @override
  Future<String> submitOrder({
    required int truckId,
    required int customerId,
    required PaymentTerm paymentTerm,
    required List<CartItem> items,
  }) async {
    // Enable offline printing only after this API has advertised stable bill numbers.
    await SaleContract.ensure(baseUrl, _client);
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
    final offlineBillNo = 'BMT-$uuid';

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
      isCredit: isCreditValue,
      isPaid: paymentTerm == PaymentTerm.cash,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      items: localItems,
    );

    final localId = await _sellLogDao.insertOfflineSale(localSale);

    // 2. A failed transport is ambiguous: keep the original UUID/bill for sync.
    http.Response response;
    try {
      final token = await preferences.getToken();
      final body = {
        "uuid": uuid,
        "billNo": offlineBillNo,
        "truckId": truckId,
        "customerId": customerId,
        "isCredit": isCreditValue == 'cash' ? null : isCreditValue,
        "totalDiscount": totalDiscount.toStringAsFixed(2),
        "totalSoldPrice": totalSoldPrice.toStringAsFixed(2),
        "items": itemsJson
      };
      response = await _client
          .post(
            Uri.parse('$baseUrl/sell-logs'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'X-Idempotency-Key': uuid,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Order response unavailable, kept pending in SQLite: $e');
      return offlineBillNo;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      SaleReceipt receipt;
      try {
        receipt = SaleReceipt.fromJson(jsonDecode(response.body));
      } catch (e) {
        debugPrint(
            'Sale accepted; response unreadable, kept pending for sync: $e');
        return offlineBillNo;
      }
      try {
        await _sellLogDao.markSynced(localId, receipt.id, receipt.billNo);
      } catch (e) {
        debugPrint('Sale saved; local marker will retry on sync: $e');
      }
      return receipt.billNo;
    }
    if (response.statusCode >= 400 &&
        response.statusCode < 500 &&
        response.statusCode != 408 &&
        response.statusCode != 429) {
      // A definitive rejection must never be shown as a completed offline sale.
      await _sellLogDao.discardRejectedSale(localId);
      throw SaleRejectedException('บันทึกการขายไม่สำเร็จ: ${response.body}');
    }
    return offlineBillNo;
  }

  @override
  Future<SaleReceipt> createSellLogFromPreOrder(
      Map<String, dynamic> payload) async {
    final token = await preferences.getToken();
    final response = await _client
        .post(
          Uri.parse('$baseUrl/sell-logs'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('สร้างรายการขายไม่สำเร็จ: ${response.body}');
    }
    final receipt = SaleReceipt.fromJson(jsonDecode(response.body));
    // Cache the server bill without deducting stock again. A cache failure must not
    // turn a successful sale into a second sale when the user retries.
    try {
      if (receipt.data['items'] != null) {
        await _sellLogDao.upsertServerSellLogsBatch([receipt.data],
            deductStockForNewSale: true);
      }
    } catch (e) {
      debugPrint('Sale saved; history cache will refresh on next sync: $e');
    }
    return receipt;
  }
}

class SaleRejectedException implements Exception {
  final String message;
  SaleRejectedException(this.message);
  @override
  String toString() => message;
}
