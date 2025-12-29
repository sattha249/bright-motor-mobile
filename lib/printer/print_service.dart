import 'dart:io';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/utils/tis620_helper.dart'; // อย่าลืม import ไฟล์นี้
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PrintService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  void _showDebugMsg(BuildContext context, String message, {bool isError = false}) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {}
  }

  Future<void> testPrinter() async {
    // Test Printer ยังใช้แบบเดิมได้เพราะเป็นภาษาอังกฤษ
    if ((await bluetooth.isConnected) ?? false) {
      bluetooth.printNewLine();
      bluetooth.printCustom("Test Print", 2, 1);
      bluetooth.printNewLine();
      bluetooth.paperCut();
    }
  }

  Future<void> printReceipt(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? paymentType,
  }) async {
    try {
      if ((await bluetooth.isConnected) != true) {
        throw Exception("Bluetooth ยังไม่เชื่อมต่อ");
      }

      _showDebugMsg(context, "กำลังเริ่มพิมพ์...");

      // 1. ตั้งค่า Code Page ภาษาไทย (สำคัญ!)
      // ส่วนใหญ่ใช้ 255 (Thai) หรือ 22 
      await bluetooth.writeBytes(Uint8List.fromList([0x1B, 0x74, 255]));

      final now = DateTime.now();
      final date = "${now.day}/${now.month}/${now.year}";
      final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // --- Header ---
      // ใช้ Tis620Helper.text แทน printCustom
      await bluetooth.writeBytes(Tis620Helper.text("BRIGHT MOTOR", isBold: true, align: 1));
      await bluetooth.writeBytes(Tis620Helper.text("STORE", align: 1));
      await bluetooth.printNewLine();

      await bluetooth.writeBytes(Tis620Helper.text("Date: $date $time"));
      if (customerName != null) {
        await bluetooth.writeBytes(Tis620Helper.text("ลูกค้า: $customerName"));
      }
      
      await bluetooth.writeBytes(Tis620Helper.text("--------------------------------"));

      // --- Items ---
      double totalAmount = 0.0;
      for (var item in cartItems) {
        final itemTotal = item.totalSoldPrice;
        totalAmount += itemTotal;
        final priceText = _formatCurrency(itemTotal);

        // ชื่อสินค้า (ภาษาไทย)
        await bluetooth.writeBytes(Tis620Helper.text(item.product.description));
        
        // รายละเอียดราคา
        String detailText = "${item.quantity} x ${item.soldPrice.toStringAsFixed(2)}      $priceText";
        if (item.discountValue > 0) detailText += " (ลด)";
        
        await bluetooth.writeBytes(Tis620Helper.text(detailText, align: 0));
      }

      // --- Footer ---
      await bluetooth.writeBytes(Tis620Helper.text("--------------------------------"));
      await bluetooth.writeBytes(Tis620Helper.text("ยอดรวม: ${_formatCurrency(totalAmount)}", isBold: true, align: 2)); // ชิดขวา
      
      await bluetooth.printNewLine();
      await bluetooth.writeBytes(Tis620Helper.text("ขอบคุณที่ใช้บริการ", align: 1));
      await bluetooth.printNewLine();

      // --- QR Code (ใช้โค้ดย่อรูปเดิม) ---
      await _printQrCodeIfExists(context);

      // --- จบ ---
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();

      _showDebugMsg(context, "พิมพ์เสร็จเรียบร้อย");

    } catch (e) {
      _showDebugMsg(context, "Error: $e", isError: true);
      print("Print Error: $e");
    }
  }

  Future<void> _printQrCodeIfExists(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/receipt_qrcode.png';
      final file = File(path);

      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        final img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageBytes));

        if (originalImage != null) {
          // ย่อรูปเพื่อให้พิมพ์เร็วและ Socket ไม่หลุด
          final img.Image resizedImage = img.copyResize(originalImage, width: 350);
          final List<int> resizedBytes = img.encodeJpg(resizedImage);

          await bluetooth.printNewLine();
          // ใช้ Tis620Helper สำหรับคำกำกับ QR
          await bluetooth.writeBytes(Tis620Helper.text("Scan to Pay", align: 1)); 
          
          bluetooth.printImageBytes(Uint8List.fromList(resizedBytes));
        }
      }
    } catch (e) {
      print("Error printing image: $e");
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}