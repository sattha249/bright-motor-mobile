import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final syncServiceProvider = Provider.autoDispose<SyncService>((ref) {
  // สร้าง instance โดยไม่ต้อง watch provider (ตาม pattern ที่คุณชอบ)
  return SyncServiceImpl();
});

abstract class SyncService {
  Future<bool> syncData();
}

class SyncServiceImpl implements SyncService {
  final SessionPreferences preferences = SessionPreferences();
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  @override
  Future<bool> syncData() async {
    try {
      final token = await preferences.getToken();
      
      // [TODO] เปลี่ยน Path นี้เป็น API ที่ต้องการยิงจริง เช่น /sync หรือ /health-check
      final url = '$baseUrl/sell-logs'; 

      final response = await defaultHttpClient().get( // หรือ .get แล้วแต่หลังบ้าน
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // ถ้า Server ตอบกลับ 200 OK ถือว่าผ่าน
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // ถ้า Error (เช่น เน็ตหลุด, Server ดับ)
      return false;
    }
  }
}