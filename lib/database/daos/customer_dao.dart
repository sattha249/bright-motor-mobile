import 'package:brightmotor_store/database/app_database.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:sqflite/sqflite.dart';

class CustomerDao {
  Future<void> insertOrUpdateBatch(List<Customer> customers) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();

    for (final customer in customers) {
      batch.insert(
        'customers',
        {
          'id': customer.id,
          'customer_no': customer.customerNo,
          'name': customer.name,
          'email': customer.email,
          'tel': customer.tel,
          'address': customer.address,
          'district': customer.district,
          'province': customer.province,
          'post_code': customer.postCode,
          'country': customer.country,
          'created_at': customer.createdAt?.toIso8601String(),
          'updated_at': customer.updatedAt?.toIso8601String(),
          'sync_status': 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Customer>> getAllCustomers({String? query}) async {
    final db = await AppDatabase.instance.database;
    String? where;
    List<dynamic>? whereArgs;

    if (query != null && query.trim().isNotEmpty) {
      where = 'name LIKE ? OR customer_no LIKE ? OR tel LIKE ?';
      whereArgs = ['%$query%', '%$query%', '%$query%'];
    }

    final maps = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) => Customer.fromJson(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Customer.fromJson(maps.first);
    }
    return null;
  }
}
