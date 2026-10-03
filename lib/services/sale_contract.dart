import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SaleContract {
  static String _key(String baseUrl) => 'stable_sale_bill_no:$baseUrl';

  static Future<void> remember(
      String baseUrl, Map<String, dynamic> health) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        _key(baseUrl), health['capabilities']?['stableSaleBillNo'] == true);
  }

  static Future<void> ensure(String baseUrl, http.Client client) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key(baseUrl)) == true) return;
    final response = await client
        .get(Uri.parse('$baseUrl/health-check'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      await remember(baseUrl, jsonDecode(response.body));
      if (prefs.getBool(_key(baseUrl)) == true) return;
    }
    throw Exception('กรุณาเชื่อมต่อและอัปเดตระบบก่อนขาย เพื่อยืนยันเลขบิล');
  }
}
