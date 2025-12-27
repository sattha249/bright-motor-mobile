import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  Future<String> _getQrCodePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/receipt_qrcode.png'; // ตั้งชื่อไฟล์ตายตัวเพื่อให้ทับของเดิม
  }

  @override
  Future<bool> syncData() async {
    try {
      // 1. Sync ข้อมูลทั่วไป (โค้ดเดิมของคุณ)
      final isDataSynced = await _syncGeneralData(); 
      
      // 2. Sync QR Code (เพิ่มใหม่)
      final isQrSynced = await _syncQrCodeImage();

      return isDataSynced && isQrSynced;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _syncGeneralData() async {
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

  Future<bool> _syncQrCodeImage() async {
    try {
      final token = await preferences.getToken();
      final url = '$baseUrl/settings/qrcode'; // API เส้นใหม่

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // ได้ข้อมูลรูปภาพมา (Bytes)
        final imageBytes = response.bodyBytes;
        
        // หาที่เก็บและบันทึกไฟล์
        final path = await _getQrCodePath();
        final file = File(path);
        
        // เขียนไฟล์ทับของเดิมทันที
        await file.writeAsBytes(imageBytes);
        print("QR Code saved at: $path");
        
        return true;
      } else {
        print("Failed to download QR: ${response.statusCode}");
        // ถ้าโหลดรูปไม่ผ่าน อาจจะ return true ไปก็ได้ถ้าไม่อยากให้ Sync ล้มเหลวทั้งหมด
        return true; 
      }
    } catch (e) {
      print("Error downloading QR: $e");
      return false;
    }
  }
}