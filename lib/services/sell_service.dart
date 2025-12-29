import 'dart:convert';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final sellServiceProvider = Provider.autoDispose<SellService>((ref) {
  // [แก้ไข] ไม่ต้องรับค่าจาก ref.watch แล้ว
  return SellServiceImpl();
});

abstract class SellService {
  Future<void> submitOrder({
    required int truckId,
    required int customerId,
    required PaymentTerm paymentTerm,
    required List<CartItem> items,
  });
  Future<void> createSellLogFromPreOrder(Map<String, dynamic> payload);
}

class SellServiceImpl implements SellService {
  final SessionPreferences preferences = SessionPreferences();
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  SellServiceImpl();

  @override
  Future<void> submitOrder({
    required int truckId,
    required int customerId,
    required PaymentTerm paymentTerm,
    required List<CartItem> items,
  }) async {
    final token = await preferences.getToken();
    final url = '$baseUrl/sell-logs'; 

    String? isCreditValue;
    switch (paymentTerm) {
      case PaymentTerm.weekly:
        isCreditValue = 'week';
        break;
      case PaymentTerm.monthly:
        isCreditValue = 'month';
        break;
      case PaymentTerm.cash:
        isCreditValue = null;
        break;
    }

    double totalDiscount = 0.0;
    double totalSoldPrice = 0.0;

    final itemsJson = items.map((item) {
      totalDiscount += item.totalDiscount;
      totalSoldPrice += item.totalSoldPrice;

      bool finalIsPaid = (paymentTerm == PaymentTerm.cash) ? true : item.isPaid;

      return {
        "productId": item.product.id,
        "quantity": item.quantity,
        "price": item.price, 
        "discount": item.discountAmount.toStringAsFixed(2), 
        "sold_price": item.soldPrice.toStringAsFixed(2),
        "is_paid": finalIsPaid
      };
    }).toList();

    final body = {
      "truckId": truckId,
      "customerId": customerId,
      "isCredit": isCreditValue,
      "totalDiscount": totalDiscount.toStringAsFixed(2),
      "totalSoldPrice": totalSoldPrice.toStringAsFixed(2),
      "items": itemsJson
    };

    final response = await defaultHttpClient().post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit order: ${response.body}');
    }
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
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create sell log: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating sell log: $e');
    }
  }
}