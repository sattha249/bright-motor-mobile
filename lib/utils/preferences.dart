import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  // Singleton pattern (เพื่อให้เรียกใช้ได้ง่ายๆ จากทุกที่)
  static final Preferences _instance = Preferences._internal();
  factory Preferences() => _instance;
  Preferences._internal();

  // --- Keys (ชื่อตัวแปรที่ใช้เก็บในเครื่อง) ---
  static const String keyToken = 'auth_token';
  static const String keyPrinterName = 'printer_name';
  static const String keyPrinterAddress = 'printer_address';

  // --- จัดการ Token (Login/Logout) ---
  
  // บันทึก Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  // ดึง Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  // ลบ Token (Logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
  }

  // --- จัดการ Printer (Connect/Disconnect) ---

  // บันทึกเครื่องพิมพ์ที่เชื่อมต่อล่าสุด
  Future<void> savePrinter(String name, String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyPrinterName, name);
    await prefs.setString(keyPrinterAddress, address);
  }

  // ดึงข้อมูลเครื่องพิมพ์ที่เคยบันทึกไว้
  Future<Map<String, String>?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(keyPrinterName);
    final address = prefs.getString(keyPrinterAddress);

    if (name != null && address != null) {
      return {'name': name, 'address': address};
    }
    return null;
  }

  // ลบข้อมูลเครื่องพิมพ์
  Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyPrinterName);
    await prefs.remove(keyPrinterAddress);
  }
}