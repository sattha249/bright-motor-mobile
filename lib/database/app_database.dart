import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('brightmotor_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable Foreign Key support in SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    const textType = 'TEXT';
    const integerType = 'INTEGER';
    const realType = 'REAL';

    // 1. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id $integerType PRIMARY KEY,
        customer_no $textType NOT NULL,
        name $textType NOT NULL,
        email $textType,
        tel $textType,
        address $textType,
        district $textType,
        province $textType,
        post_code $textType,
        country $textType,
        created_at $textType,
        updated_at $textType,
        sync_status $textType DEFAULT 'synced'
      )
    ''');

    // 2. Users Table
    await db.execute('''
      CREATE TABLE users (
        id $integerType PRIMARY KEY,
        username $textType NOT NULL,
        email $textType,
        fullname $textType,
        tel $textType,
        role $textType,
        truck_id $integerType,
        truck_name $textType,
        plate_number $textType,
        plate_province $textType,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // 3. Products Table (Master Product Catalog)
    await db.execute('''
      CREATE TABLE products (
        id $integerType PRIMARY KEY,
        product_code $textType,
        zone $textType,
        category $textType,
        description $textType,
        brand $textType,
        model $textType,
        cost_price $realType,
        sell_price $realType,
        unit $textType,
        max_quantity $realType,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // 3.1 Truck Stocks Table (Stock in truck linked to Product)
    await db.execute('''
      CREATE TABLE truck_stocks (
        id $integerType PRIMARY KEY,
        truck_id $integerType NOT NULL,
        product_id $integerType NOT NULL,
        quantity $realType NOT NULL,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 4. PreOrders Table (Header)
    await db.execute('''
      CREATE TABLE pre_orders (
        local_id $integerType PRIMARY KEY AUTOINCREMENT,
        id $integerType,
        uuid $textType UNIQUE,
        bill_no $textType NOT NULL,
        truck_id $integerType,
        customer_id $integerType,
        user_id $integerType,
        status $textType DEFAULT 'Pending',
        total_price $realType,
        total_discount $realType,
        total_sold_price $realType,
        is_credit $textType,
        sync_status $textType DEFAULT 'pending',
        created_at $textType,
        updated_at $textType
      )
    ''');

    // 4.1 PreOrder Items Table (Detail)
    await db.execute('''
      CREATE TABLE pre_order_items (
        local_id $integerType PRIMARY KEY AUTOINCREMENT,
        pre_order_local_id $integerType NOT NULL,
        product_id $integerType NOT NULL,
        quantity $realType NOT NULL,
        price $realType NOT NULL,
        discount $realType DEFAULT 0,
        sold_price $realType NOT NULL,
        is_paid $integerType DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (pre_order_local_id) REFERENCES pre_orders (local_id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // 5. Sell Logs Table (Header - Sales History & Offline Sales)
    await db.execute('''
      CREATE TABLE sell_logs (
        local_id $integerType PRIMARY KEY AUTOINCREMENT,
        id $integerType,
        uuid $textType UNIQUE,
        bill_no $textType NOT NULL,
        truck_id $integerType,
        truck_name $textType,
        customer_id $integerType,
        user_id $integerType,
        total_price $realType,
        pending_amount $realType DEFAULT 0,
        interest $realType DEFAULT 0,
        is_paid $integerType DEFAULT 0,
        total_discount $realType DEFAULT 0,
        total_sold_price $realType,
        is_credit $textType,
        is_preorder $integerType DEFAULT 0,
        sync_status $textType DEFAULT 'pending',
        created_at $textType,
        updated_at $textType
      )
    ''');

    // 5.1 Sell Log Items Table (Detail)
    await db.execute('''
      CREATE TABLE sell_log_items (
        local_id $integerType PRIMARY KEY AUTOINCREMENT,
        sell_log_local_id $integerType NOT NULL,
        product_id $integerType NOT NULL,
        quantity $realType NOT NULL,
        returned_quantity $realType DEFAULT 0,
        price $realType NOT NULL,
        total_price $realType NOT NULL,
        discount $realType DEFAULT 0,
        sold_price $realType NOT NULL,
        is_paid $integerType DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (sell_log_local_id) REFERENCES sell_logs (local_id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
