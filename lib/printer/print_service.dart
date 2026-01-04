import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/utils/preferences.dart';
import 'package:brightmotor_store/utils/tis620_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PrintService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final Preferences preferences = Preferences();

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

  // --- Helper: จับภาพ Widget ให้เป็นรูป ---
  Future<Uint8List> _captureWidgetToImage(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // pixelRatio 2.0 ให้ภาพชัดเจนสำหรับ QR Code แต่อย่าเยอะเกินเดี๋ยวไฟล์ใหญ่
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print("Error capturing widget: $e");
      rethrow;
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

      bool useImageMode = await preferences.getPrinterImageMode();

      if (useImageMode) {
        await _printReceiptAsImage(context, cartItems, customerName: customerName, paymentType: paymentType);
      } else {
        await _printReceiptAsText(context, cartItems, customerName: customerName, paymentType: paymentType);
      }

      _showDebugMsg(context, "พิมพ์เสร็จเรียบร้อย");

    } catch (e) {
      _showDebugMsg(context, "Error: $e", isError: true);
      print("Print Error: $e");
    }
  }

  // --- โหมดปกติ (Text Mode) ---
  Future<void> _printReceiptAsText(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? paymentType,
  }) async {
      int codePage = await preferences.getPrinterCodePage();
      
      await bluetooth.writeBytes(Uint8List.fromList([0x1B, 0x40])); 
      await Future.delayed(const Duration(milliseconds: 200));
      await bluetooth.writeBytes(Uint8List.fromList([0x1B, 0x74, codePage]));

      final now = DateTime.now();
      final date = "${now.day}/${now.month}/${now.year}";
      final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      await bluetooth.writeBytes(Tis620Helper.text("BRIGHT MOTOR", isBold: true, align: 1));
      await bluetooth.writeBytes(Tis620Helper.text("STORE", align: 1));
      await bluetooth.printNewLine();

      await bluetooth.writeBytes(Tis620Helper.text("Date: $date $time"));
      if (customerName != null) {
        await bluetooth.writeBytes(Tis620Helper.text("ลูกค้า: $customerName"));
      }
      
      await bluetooth.writeBytes(Tis620Helper.text("--------------------------------"));

      double totalAmount = 0.0;
      for (var item in cartItems) {
        final itemTotal = item.totalSoldPrice;
        totalAmount += itemTotal;
        final priceText = _formatCurrency(itemTotal);

        await bluetooth.writeBytes(Tis620Helper.text(item.product.description));
        
        String detailText = "${item.quantity} x ${item.soldPrice.toStringAsFixed(2)}      $priceText";
        if (item.discountValue > 0) detailText += " (ลด)";
        
        await bluetooth.writeBytes(Tis620Helper.text(detailText, align: 0));
      }

      await bluetooth.writeBytes(Tis620Helper.text("--------------------------------"));
      await bluetooth.writeBytes(Tis620Helper.text("ยอดรวม: ${_formatCurrency(totalAmount)}", isBold: true, align: 2));
      
      await bluetooth.printNewLine();
      await bluetooth.writeBytes(Tis620Helper.text("ขอบคุณที่ใช้บริการ", align: 1));
      await bluetooth.printNewLine();

      await _printQrCodeIfExists(context); // พิมพ์ QR แยกในโหมด Text

      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
  }

  // --- โหมดรูปภาพ (Image Mode) [แก้ไขใหม่] ---
  Future<void> _printReceiptAsImage(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? paymentType,
  }) async {
    final GlobalKey receiptKey = GlobalKey();

    // 1. เตรียมรูป QR Code (ถ้ามี)
    File? qrFile;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/receipt_qrcode.png');
      if (await file.exists()) {
        qrFile = file;
      }
    } catch (e) {
      print("Error loading QR for image mode: $e");
    }

    // คำนวณยอดรวม
    double totalAmount = 0.0;
    for (var item in cartItems) {
      totalAmount += item.totalSoldPrice;
    }
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

    // 2. สร้าง Widget ใบเสร็จ (รวม QR Code เข้าไปในนี้เลย)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white, // พื้นขาวสำคัญมาก
          insetPadding: EdgeInsets.zero, // ให้เต็มจอเพื่อความชัวร์ในการ render
          child: SingleChildScrollView(
            child: RepaintBoundary(
              key: receiptKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                width: 380, // กว้างประมาณกระดาษ 58mm (ความละเอียด)
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text("BRIGHT MOTOR", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black))),
                    Center(child: Text("STORE", style: TextStyle(fontSize: 20, color: Colors.black))),
                    Divider(color: Colors.black, thickness: 1.5),
                    
                    Text("Date: $dateStr", style: TextStyle(fontSize: 16, color: Colors.black)),
                    if (customerName != null) 
                      Text("ลูกค้า: $customerName", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    
                    Divider(color: Colors.black),
                    
                    // รายการสินค้า
                    ...cartItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.description, style: TextStyle(fontSize: 16, color: Colors.black)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${item.quantity} x ${item.soldPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 14, color: Colors.black)),
                              Text(_formatCurrency(item.totalSoldPrice), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                          if (item.discountValue > 0) 
                            Text("  (ส่วนลด ${item.discountValue})", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black)),
                        ],
                      ),
                    )),
                    
                    Divider(color: Colors.black, thickness: 1.5),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ยอดรวม:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(_formatCurrency(totalAmount), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    Center(child: Text("ขอบคุณที่ใช้บริการ", style: TextStyle(fontSize: 18, color: Colors.black))),
                    SizedBox(height: 10),

                    // [สำคัญ] ฝัง QR Code ลงในใบเสร็จเลย
                    if (qrFile != null) ...[
                      SizedBox(height: 10),
                      Center(child: Text("Scan to Pay", style: TextStyle(fontSize: 16, color: Colors.black))),
                      SizedBox(height: 5),
                      Center(
                        child: Image.file(
                          qrFile,
                          width: 200, // ขนาด QR Code
                          height: 200,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                    // เผื่อพื้นที่ด้านล่างนิดหน่อย
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // รอให้ Widget วาดเสร็จ
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // 3. แปลงเป็นรูปภาพ
      Uint8List pngBytes = await _captureWidgetToImage(receiptKey);
      Navigator.of(context).pop(); // ปิด Dialog

      final img.Image? originalImage = img.decodeImage(pngBytes);
      if (originalImage != null) {
        // Resize ให้พอดีหน้ากระดาษ (370px)
        final img.Image resizedImage = img.copyResize(originalImage, width: 370 ,interpolation: img.Interpolation.cubic);
        // แปลงเป็นขาวดำ (Grayscale) เพื่อลดขนาดข้อมูล
        final img.Image bwImage = img.luminanceThreshold(resizedImage, threshold: 0.5);

        // 4. เตรียมเครื่องพิมพ์ (Reset)
        await bluetooth.writeBytes(Uint8List.fromList([0x1B, 0x40])); 
        await Future.delayed(const Duration(milliseconds: 200)); 

        // 5. เทคนิค Chunking (หั่นภาพเป็นชิ้นเล็กๆ แล้วส่งทีละนิด)
        // เพื่อป้องกัน Buffer Overflow ที่ทำให้ภาพขาด
        int imageHeight = bwImage.height;
        int chunkHeight = 100; // ส่งทีละ 100 pixel แนวตั้ง
        
        for (int y = 0; y < imageHeight; y += chunkHeight) {
          int h = (y + chunkHeight > imageHeight) ? (imageHeight - y) : chunkHeight;
          
          // ตัดภาพส่วนนี้มา
          img.Image chunk = img.copyCrop(bwImage, x: 0, y: y, width: bwImage.width, height: h);
          
          // แปลงเป็น JPG (เร็วกว่า PNG บน bluetooth บางรุ่น)
          final List<int> chunkBytes = img.encodeJpg(chunk, quality: 100);
          
          // ส่งไปพิมพ์
          bluetooth.printImageBytes(Uint8List.fromList(chunkBytes));
          
          // [สำคัญ] พักหายใจนิดนึงระหว่างก้อน
          await Future.delayed(const Duration(milliseconds: 50)); 
        }

        // 6. จบงาน
        await Future.delayed(const Duration(milliseconds: 1000)); // รอให้พิมพ์หมด buffer
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.paperCut();
      }
    } catch (e) {
      Navigator.of(context).pop(); 
      throw e;
    }
  }

  // --- Helper Methods เดิม ---
  Future<void> findThaiCodePage(BuildContext context) async {
    if ((await bluetooth.isConnected) != true) return;
    List<int> codesToTest = [255, 22, 17, 16, 44, 13];
    await bluetooth.printNewLine();
    await bluetooth.printCustom("--- CODE PAGE TEST ---", 1, 1);
    for (int code in codesToTest) {
      await bluetooth.writeBytes(Uint8List.fromList([0x1B, 0x74, code]));
      String message = "Code $code: ทดสอบภาษาไทย";
      await bluetooth.writeBytes(Tis620Helper.text(message));
    }
    await bluetooth.printNewLine();
    await bluetooth.printNewLine();
    await bluetooth.paperCut();
  }

  Future<void> _printQrCodeIfExists(BuildContext context) async {
    // ฟังก์ชันนี้เก็บไว้ใช้กับ Text Mode เท่านั้น
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/receipt_qrcode.png');
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        final img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageBytes));
        if (originalImage != null) {
          final img.Image resizedImage = img.copyResize(originalImage, width: 350);
          final List<int> resizedBytes = img.encodeJpg(resizedImage);
          await bluetooth.printNewLine();
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