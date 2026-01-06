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
  static const String keyPrinterCodePage = 'printer_code_page';
  static const String keyPrinterImageMode = 'printer_image_mode';
  static const String keyPrinterFontSize = "printer_font_size";
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

  Future<void> savePrinterCodePage(int code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyPrinterCodePage, code);
  }

  // [New] Get Printer Code Page (default to 22 if not set)
  Future<int> getPrinterCodePage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyPrinterCodePage) ?? 22;
  }

  Future<void> savePrinterImageMode(bool isImageMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyPrinterImageMode, isImageMode);
  }

  Future<bool> getPrinterImageMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyPrinterImageMode) ?? false;
  }
  // [เพิ่ม] ดึงค่าขนาดตัวอักษร (Default 18.0)
  Future<double> getPrinterFontSize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyPrinterFontSize) ?? 18.0; 
  }

  // [เพิ่ม] บันทึกค่าขนาดตัวอักษร
  Future<void> setPrinterFontSize(double size) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyPrinterFontSize, size);
  }
  
}