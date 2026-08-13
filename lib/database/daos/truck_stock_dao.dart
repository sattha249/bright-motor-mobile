import 'package:brightmotor_store/database/app_database.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/models/truck_stock_model.dart';
import 'package:sqflite/sqflite.dart';

class TruckStockDao {
  Future<void> saveTruckStocksBatch(
      int truckId, List<TruckStockItem> items) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();

    for (final item in items) {
      // 1. Insert/Update Product master table
      batch.insert(
        'products',
        {
          'id': item.product.id,
          'product_code': item.product.productCode,
          'description': item.product.description,
          'sell_price': double.tryParse(item.product.sellPrice) ?? 0.0,
          'unit': item.product.unit,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert/Update TruckStock table
      batch.insert(
        'truck_stocks',
        {
          'id': item.id,
          'truck_id': truckId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<TruckStockItem>> getTruckStocks(int truckId) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.rawQuery('''
      SELECT ts.id, ts.truck_id, ts.quantity,
             p.id as p_id, p.product_code, p.description, p.sell_price, p.unit
      FROM truck_stocks ts
      JOIN products p ON ts.product_id = p.id
      WHERE ts.truck_id = ? AND ts.quantity > 0
      ORDER BY p.description ASC
    ''', [truckId]);

    return maps.map((map) {
      return TruckStockItem(
        id: map['id'] as int,
        truckId: map['truck_id'] as int,
        quantity: (map['quantity'] as num).toInt(),
        product: ProductDetail(
          id: map['p_id'] as int,
          productCode: (map['product_code'] as String?) ?? '-',
          description: (map['description'] as String?) ?? '-',
          sellPrice: (map['sell_price'] as num?)?.toStringAsFixed(2) ?? '0.00',
          unit: (map['unit'] as String?) ?? '-',
        ),
      );
    }).toList();
  }

  Future<double> getAvailableQuantity(int truckId, int productId,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? await AppDatabase.instance.database;
    final maps = await db.query(
      'truck_stocks',
      columns: ['quantity'],
      where: 'truck_id = ? AND product_id = ?',
      whereArgs: [truckId, productId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return (maps.first['quantity'] as num).toDouble();
    }
    return 0.0;
  }

  Future<bool> deductStockQuantity(
      int truckId, int productId, double qtyToDeduct,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? await AppDatabase.instance.database;
    final currentQty =
        await getAvailableQuantity(truckId, productId, executor: db);
    if (currentQty < qtyToDeduct) {
      return false; // Not enough stock in offline database!
    }

    final newQty = currentQty - qtyToDeduct;
    await db.update(
      'truck_stocks',
      {'quantity': newQty, 'updated_at': DateTime.now().toIso8601String()},
      where: 'truck_id = ? AND product_id = ?',
      whereArgs: [truckId, productId],
    );
    return true;
  }
}
