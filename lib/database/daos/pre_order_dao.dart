import 'package:brightmotor_store/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class LocalPreOrder {
  final int? localId;
  final int? id; // Server ID
  final String uuid; // Idempotency UUID
  final String billNo;
  final int truckId;
  final int customerId;
  final int userId;
  final String status;
  final double totalPrice;
  final double totalDiscount;
  final double totalSoldPrice;
  final String isCredit;
  final String syncStatus; // 'pending', 'synced', 'failed'
  final DateTime createdAt;
  final List<LocalPreOrderItem> items;

  LocalPreOrder({
    this.localId,
    this.id,
    required this.uuid,
    required this.billNo,
    required this.truckId,
    required this.customerId,
    required this.userId,
    this.status = 'Pending',
    required this.totalPrice,
    this.totalDiscount = 0.0,
    required this.totalSoldPrice,
    this.isCredit = 'cash',
    this.syncStatus = 'pending',
    required this.createdAt,
    this.items = const [],
  });
}

class LocalPreOrderItem {
  final int? localId;
  final int? preOrderLocalId;
  final int productId;
  final double quantity;
  final double price;
  final double discount;
  final double soldPrice;
  final bool isPaid;

  LocalPreOrderItem({
    this.localId,
    this.preOrderLocalId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    required this.soldPrice,
    this.isPaid = false,
  });
}

class PreOrderDao {
  Future<int> insertOfflinePreOrder(LocalPreOrder preOrder) async {
    final db = await AppDatabase.instance.database;
    return await db.transaction((txn) async {
      final preOrderId = await txn.insert('pre_orders', {
        'id': preOrder.id,
        'uuid': preOrder.uuid,
        'bill_no': preOrder.billNo,
        'truck_id': preOrder.truckId,
        'customer_id': preOrder.customerId,
        'user_id': preOrder.userId,
        'status': preOrder.status,
        'total_price': preOrder.totalPrice,
        'total_discount': preOrder.totalDiscount,
        'total_sold_price': preOrder.totalSoldPrice,
        'is_credit': preOrder.isCredit,
        'sync_status': preOrder.syncStatus,
        'created_at': preOrder.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      for (final item in preOrder.items) {
        await txn.insert('pre_order_items', {
          'pre_order_local_id': preOrderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.price,
          'discount': item.discount,
          'sold_price': item.soldPrice,
          'is_paid': item.isPaid ? 1 : 0,
          'created_at': preOrder.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return preOrderId;
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncPreOrders() async {
    final db = await AppDatabase.instance.database;
    final preOrders = await db.query(
      'pre_orders',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    List<Map<String, dynamic>> results = [];
    for (final order in preOrders) {
      final items = await db.query(
        'pre_order_items',
        where: 'pre_order_local_id = ?',
        whereArgs: [order['local_id']],
      );
      final mutableOrder = Map<String, dynamic>.from(order);
      mutableOrder['items'] = items;
      results.add(mutableOrder);
    }
    return results;
  }

  Future<void> markSynced(int localId, int serverId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'pre_orders',
      {
        'id': serverId,
        'sync_status': 'synced',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }
}
