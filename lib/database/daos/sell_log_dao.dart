import 'package:brightmotor_store/database/app_database.dart';
import 'package:brightmotor_store/database/daos/truck_stock_dao.dart';
import 'package:sqflite/sqflite.dart';

class LocalSellLog {
  final int? localId;
  final int? id; // Server ID
  final String uuid; // Idempotency UUID
  final String billNo;
  final int truckId;
  final String? truckName;
  final int customerId;
  final int userId;
  final double totalPrice;
  final double pendingAmount;
  final double interest;
  final bool isPaid;
  final double totalDiscount;
  final double totalSoldPrice;
  final String isCredit;
  final bool isPreorder;
  final String syncStatus; // 'pending', 'synced', 'failed'
  final DateTime createdAt;
  final List<LocalSellLogItem> items;

  LocalSellLog({
    this.localId,
    this.id,
    required this.uuid,
    required this.billNo,
    required this.truckId,
    this.truckName,
    required this.customerId,
    required this.userId,
    required this.totalPrice,
    this.pendingAmount = 0.0,
    this.interest = 0.0,
    this.isPaid = false,
    this.totalDiscount = 0.0,
    required this.totalSoldPrice,
    this.isCredit = 'cash',
    this.isPreorder = false,
    this.syncStatus = 'pending',
    required this.createdAt,
    this.items = const [],
  });
}

class LocalSellLogItem {
  final int? localId;
  final int? sellLogLocalId;
  final int productId;
  final double quantity;
  final double returnedQuantity;
  final double price;
  final double totalPrice;
  final double discount;
  final double soldPrice;
  final bool isPaid;

  LocalSellLogItem({
    this.localId,
    this.sellLogLocalId,
    required this.productId,
    required this.quantity,
    this.returnedQuantity = 0.0,
    required this.price,
    required this.totalPrice,
    this.discount = 0.0,
    required this.soldPrice,
    this.isPaid = false,
  });
}

class SellLogDao {
  final TruckStockDao _truckStockDao = TruckStockDao();

  Future<int> insertOfflineSale(LocalSellLog sale) async {
    final db = await AppDatabase.instance.database;

    return await db.transaction((txn) async {
      // 1. Insert header
      final sellLogId = await txn.insert('sell_logs', {
        'id': sale.id,
        'uuid': sale.uuid,
        'bill_no': sale.billNo,
        'truck_id': sale.truckId,
        'truck_name': sale.truckName,
        'customer_id': sale.customerId,
        'user_id': sale.userId,
        'total_price': sale.totalPrice,
        'pending_amount': sale.pendingAmount,
        'interest': sale.interest,
        'is_paid': sale.isPaid ? 1 : 0,
        'total_discount': sale.totalDiscount,
        'total_sold_price': sale.totalSoldPrice,
        'is_credit': sale.isCredit,
        'is_preorder': sale.isPreorder ? 1 : 0,
        'sync_status': sale.syncStatus,
        'created_at': sale.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Insert items and deduct local truck stock
      for (final item in sale.items) {
        await txn.insert('sell_log_items', {
          'sell_log_local_id': sellLogId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'returned_quantity': item.returnedQuantity,
          'price': item.price,
          'total_price': item.totalPrice,
          'discount': item.discount,
          'sold_price': item.soldPrice,
          'is_paid': item.isPaid ? 1 : 0,
          'created_at': sale.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Deduct offline stock in truck using active transaction executor!
        await _truckStockDao.deductStockQuantity(
          sale.truckId,
          item.productId,
          item.quantity,
          executor: txn,
        );
      }

      return sellLogId;
    });
  }

  Future<void> upsertServerSellLogsBatch(
      List<Map<String, dynamic>> rawLogs) async {
    final db = await AppDatabase.instance.database;
    for (final logMap in rawLogs) {
      final serverId = logMap['id'] as int?;
      if (serverId == null) continue;

      final existing = await db.query(
        'sell_logs',
        where: 'id = ?',
        whereArgs: [serverId],
        limit: 1,
      );

      final totalPrice = (logMap['total_price'] as num?)?.toDouble() ?? 0.0;
      final totalDiscount =
          (logMap['total_discount'] as num?)?.toDouble() ?? 0.0;
      final totalSoldPrice =
          (logMap['total_sold_price'] as num?)?.toDouble() ?? totalPrice;

      if (existing.isNotEmpty) {
        final localId = existing.first['local_id'] as int;
        await db.update(
          'sell_logs',
          {
            'total_price': totalPrice,
            'total_discount': totalDiscount,
            'total_sold_price': totalSoldPrice,
            'sync_status': 'synced',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'local_id = ?',
          whereArgs: [localId],
        );
      } else {
        await db.transaction((txn) async {
          final localId = await txn.insert('sell_logs', {
            'id': serverId,
            'bill_no': logMap['bill_no'] ?? '-',
            'truck_id': logMap['truck_id'],
            'truck_name': logMap['truck_name'],
            'customer_id': logMap['customer_id'],
            'user_id': logMap['user_id'],
            'total_price': totalPrice,
            'pending_amount':
                (logMap['pending_amount'] as num?)?.toDouble() ?? 0.0,
            'interest': (logMap['interest'] as num?)?.toDouble() ?? 0.0,
            'is_paid': (logMap['is_paid'] == true || logMap['is_paid'] == 1)
                ? 1
                : 0,
            'total_discount': totalDiscount,
            'total_sold_price': totalSoldPrice,
            'is_credit': logMap['is_credit'] ?? 'cash',
            'is_preorder': (logMap['is_preorder'] == true ||
                    logMap['is_preorder'] == 1)
                ? 1
                : 0,
            'sync_status': 'synced',
            'created_at': logMap['created_at'] ??
                DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          final items = logMap['items'] as List?;
          if (items != null) {
            for (final itemMap in items) {
              await txn.insert('sell_log_items', {
                'sell_log_local_id': localId,
                'product_id': itemMap['product_id'] ?? itemMap['productId'] ?? 0,
                'quantity': (itemMap['quantity'] as num?)?.toDouble() ?? 0.0,
                'returned_quantity':
                    (itemMap['returned_quantity'] as num?)?.toDouble() ?? 0.0,
                'price': (itemMap['price'] as num?)?.toDouble() ?? 0.0,
                'total_price':
                    (itemMap['total_price'] as num?)?.toDouble() ?? 0.0,
                'discount': (itemMap['discount'] as num?)?.toDouble() ?? 0.0,
                'sold_price':
                    (itemMap['sold_price'] as num?)?.toDouble() ?? 0.0,
                'is_paid': (itemMap['is_paid'] == true ||
                        itemMap['is_paid'] == 1)
                    ? 1
                    : 0,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            }
          }
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAllSellLogs(int truckId) async {
    final db = await AppDatabase.instance.database;
    final sales = await db.rawQuery('''
      SELECT sl.*, c.name as customer_name, c.tel as customer_tel
      FROM sell_logs sl
      LEFT JOIN customers c ON sl.customer_id = c.id
      WHERE sl.truck_id = ?
      ORDER BY sl.created_at DESC
    ''', [truckId]);

    List<Map<String, dynamic>> results = [];
    for (final sale in sales) {
      final items = await db.rawQuery('''
        SELECT sli.*, p.description, p.product_code, p.unit
        FROM sell_log_items sli
        LEFT JOIN products p ON sli.product_id = p.id
        WHERE sli.sell_log_local_id = ?
      ''', [sale['local_id']]);

      final mutableSale = Map<String, dynamic>.from(sale);
      mutableSale['items'] = items.map((i) {
        final m = Map<String, dynamic>.from(i);
        m['product'] = {
          'description': i['description'] ?? 'สินค้า',
          'product_code': i['product_code'] ?? '-',
          'unit': i['unit'] ?? '',
        };
        return m;
      }).toList();

      mutableSale['customer'] = {
        'name': sale['customer_name'] ?? 'ลูกค้าทั่วไป',
        'tel': sale['customer_tel'] ?? '-',
      };
      results.add(mutableSale);
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> getPendingSyncSales() async {
    final db = await AppDatabase.instance.database;
    final sales = await db.query(
      'sell_logs',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    List<Map<String, dynamic>> results = [];
    for (final sale in sales) {
      final items = await db.query(
        'sell_log_items',
        where: 'sell_log_local_id = ?',
        whereArgs: [sale['local_id']],
      );
      final mutableSale = Map<String, dynamic>.from(sale);
      mutableSale['items'] = items;
      results.add(mutableSale);
    }
    return results;
  }

  Future<void> markSynced(int localId, int serverId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'sell_logs',
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
