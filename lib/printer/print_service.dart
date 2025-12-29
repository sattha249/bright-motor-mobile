import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/models/cart_model.dart'; // [แก้ไข] ใช้ CartItem แทน Product Model เดิม
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class PrintService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  void _showDebugMsg(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 1), // แสดงแป๊บเดียวพอ
      ),
    );
  }

  Future<void> testPrinter() async {
    if ((await bluetooth.isConnected) ?? false) {
      bluetooth.printNewLine();
      bluetooth.printCustom("Test Print", 2, 1); // Centered, Large
      bluetooth.printNewLine();
      bluetooth.printCustom("This is a test print.", 1, 0); // Normal, Left
      bluetooth.printNewLine();
      bluetooth.paperCut(); 
    } else {
      throw Exception("Printer is not connected");
    }
  }

  // [แก้ไข] เปลี่ยนจาก Map<Product, int> เป็น List<CartItem>
  // และเพิ่ม option รับชื่อลูกค้า หรือประเภทการชำระเงิน (ถ้าต้องการ)
Future<void> printReceipt(
    BuildContext context, 
    List<CartItem> cartItems, 
    {String? customerName, String? paymentType}
  ) async {
    _showDebugMsg(context, "1. เริ่มต้นการพิมพ์..."); // Checkpoint 1

    try {
      final isConnected = await bluetooth.isConnected;
      if (isConnected != true) {
        throw Exception("Bluetooth ยังไม่เชื่อมต่อ (isConnected = false)");
      }

      _showDebugMsg(context, "2. เชื่อมต่อสำเร็จ กำลังเตรียมข้อมูล..."); // Checkpoint 2

      final now = DateTime.now();
      final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // --- เริ่มส่งคำสั่งพิมพ์ ---
      bluetooth.printNewLine();
      bluetooth.printCustom("BRIGHT MOTOR", 3, 1);
      bluetooth.printCustom("STORE", 1, 1);
      bluetooth.printNewLine();
      
      bluetooth.printLeftRight("Date:", "$date $time", 1);
      if (customerName != null) {
        bluetooth.printLeftRight("Customer:", customerName, 1);
      }
      
      bluetooth.printCustom("--------------------------------", 1, 1);

      _showDebugMsg(context, "3. กำลังวนลูปรายการสินค้า..."); // Checkpoint 3

      double totalAmount = 0.0;
      for (var item in cartItems) {
        final itemTotal = item.totalSoldPrice;
        totalAmount += itemTotal;
        final priceText = itemTotal.toStringAsFixed(2); // เอา format ง่ายๆ ก่อนกันเหนียว

        bluetooth.printCustom(item.product.description, 1, 0);
        bluetooth.printLeftRight("${item.quantity} x ${item.soldPrice}", priceText, 1);
      }

      bluetooth.printCustom("--------------------------------", 1, 1);
      bluetooth.printLeftRight("TOTAL", totalAmount.toStringAsFixed(2), 3);
      
      bluetooth.printNewLine();
      bluetooth.printCustom("Thank You!", 2, 1);
      bluetooth.printNewLine();

      _showDebugMsg(context, "4. พิมพ์ข้อความเสร็จ ต่อไป QR Code..."); // Checkpoint 4

      // [จุดเสี่ยงตาย] การพิมพ์รูปภาพ
      await _printQrCodeIfExists(context); 

      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut(); 
      
      _showDebugMsg(context, "✅ พิมพ์เสร็จสมบูรณ์!"); // Checkpoint สุดท้าย

    } catch (e, stacktrace) {
      // ถ้าพัง ให้เด้ง Dialog แจ้งเตือนเพื่อนทันที
      print("Print Error: $e");
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาดในการพิมพ์"),
          content: SingleChildScrollView(
            child: Text("Error: $e\n\nStacktrace: $stacktrace"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ปิด"))
          ],
        ),
      );
    }
  }
Future<void> _printQrCodeIfExists(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/receipt_qrcode.png';
      final file = File(path);

      if (await file.exists()) {
        _showDebugMsg(context, "เจอไฟล์ QR Code กำลังเตรียมพิมพ์...");
        
        // 1. อ่านไฟล์รูป
        final List<int> imageBytes = await file.readAsBytes();
        
        // 2. Decode รูปภาพเพื่อเตรียมย่อ
        final img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageBytes));

        if (originalImage != null) {
          // 3. ย่อขนาดรูปภาพ (Resize)
          // เครื่องพิมพ์ 58mm กว้างประมาณ 384 px
          // เครื่องพิมพ์ 80mm กว้างประมาณ 576 px
          // แนะนำให้ย่อเหลือความกว้างประมาณ 300-350 px กำลังดี
          final img.Image resizedImage = img.copyResize(originalImage, width: 350);

          // 4. Encode กลับเป็น JPG หรือ PNG (แนะนำ JPG สำหรับ Printer บางรุ่นที่เมไมน้อย)
          final List<int> resizedBytes = img.encodeJpg(resizedImage);

          bluetooth.printNewLine();
          bluetooth.printCustom("Scan to Pay", 1, 1);
          
          // 5. ส่งรูปที่ย่อแล้วไปพิมพ์
          // ใช้ Uint8List.fromList() แปลงกลับ
          bluetooth.printImageBytes(Uint8List.fromList(resizedBytes)); 
          
          _showDebugMsg(context, "ส่งคำสั่งพิมพ์รูปเรียบร้อย");
        } else {
           _showDebugMsg(context, "Decode รูปภาพไม่สำเร็จ", isError: true);
        }
      } else {
        _showDebugMsg(context, "⚠️ ไม่พบไฟล์ QR Code (ข้าม)");
      }
    } catch (e) {
      _showDebugMsg(context, "Error รูปภาพ: $e", isError: true);
      print("Error printing image: $e");
    }
  }
  // Helper สำหรับจัด Format เงิน (1,000.00)
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}