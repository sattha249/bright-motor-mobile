import 'package:brightmotor_store/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class LocalUser {
  final int id;
  final String username;
  final String? email;
  final String? fullname;
  final String? tel;
  final String? role;
  final int? truckId;
  final String? truckName;
  final String? plateNumber;
  final String? plateProvince;

  LocalUser({
    required this.id,
    required this.username,
    this.email,
    this.fullname,
    this.tel,
    this.role,
    this.truckId,
    this.truckName,
    this.plateNumber,
    this.plateProvince,
  });

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String?,
      fullname: map['fullname'] as String?,
      tel: map['tel'] as String?,
      role: map['role'] as String?,
      truckId: map['truck_id'] as int?,
      truckName: map['truck_name'] as String?,
      plateNumber: map['plate_number'] as String?,
      plateProvince: map['plate_province'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullname': fullname,
      'tel': tel,
      'role': role,
      'truck_id': truckId,
      'truck_name': truckName,
      'plate_number': plateNumber,
      'plate_province': plateProvince,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class UserDao {
  Future<void> saveUser(LocalUser user) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalUser?> getUser(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return LocalUser.fromMap(maps.first);
    }
    return null;
  }

  Future<LocalUser?> getActiveUser() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      'users',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return LocalUser.fromMap(maps.first);
    }
    return null;
  }
}
