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
      // pixelRatio 3.0 ให้ภาพชัดเจน
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); 
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print("Error capturing widget: $e");
      rethrow;
    }
  }

  // [แก้ไข] เปลี่ยน parameter เป็นรับ isCredit เพื่อใช้ทำ Logic
  Future<void> printReceipt(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? customerAddress,
    String? customerPhone, 
    String? salespersonName,
    bool isCredit = false, // เปลี่ยนจาก paymentType เป็น isCredit
  }) async {
    try {
      // comment this for test ja
      if ((await bluetooth.isConnected) != true) {
        throw Exception("Bluetooth ยังไม่เชื่อมต่อ");
      }

      _showDebugMsg(context, "กำลังเริ่มพิมพ์...");

      bool useImageMode = await preferences.getPrinterImageMode();

     if (useImageMode) {
        await _printReceiptAsImage(
          context, 
          cartItems, 
          customerName: customerName, 
          customerAddress: customerAddress,
          customerPhone: customerPhone,     
          salespersonName: salespersonName, 
          isCredit: isCredit
        );
      } else {
        await _printReceiptAsText(
          context, 
          cartItems, 
          customerName: customerName, 
          customerAddress: customerAddress, 
          customerPhone: customerPhone,    
          salespersonName: salespersonName,
          isCredit: isCredit
        );
      }

      _showDebugMsg(context, "พิมพ์เสร็จเรียบร้อย");

    } catch (e) {
      _showDebugMsg(context, "Error: $e", isError: true);
      print("Print Error: $e");
    }
  }

  // --- โหมดปกติ (Text Mode) [แก้ไขตาม requirement] ---
  Future<void> _printReceiptAsText(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? customerAddress,
    String? customerPhone, 
    String? salespersonName,
    required bool isCredit,
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
      // [เพิ่ม] ที่อยู่และเบอร์โทร
      if (customerAddress != null && customerAddress.isNotEmpty) {
        await bluetooth.writeBytes(Tis620Helper.text("ที่อยู่: $customerAddress"));
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        await bluetooth.writeBytes(Tis620Helper.text("โทร: $customerPhone"));
      }

      // [เพิ่ม] ประเภทการชำระ
      String paymentLabel = isCredit ? "เครดิต" : "เงินสด";
      await bluetooth.writeBytes(Tis620Helper.text("การชำระเงิน: $paymentLabel"));

      if (salespersonName != null) {
        await bluetooth.writeBytes(Tis620Helper.text("พนักงานขาย: $salespersonName"));
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

      await _printQrCodeIfExists(context);

      // [เพิ่ม] ข้อความแจ้งเตือนดอกเบี้ย (เฉพาะเครดิต)
        await bluetooth.printNewLine();
        await bluetooth.writeBytes(Tis620Helper.text(
          "*** หมายเหตุ ***", 
          align: 1, isBold: true
        ));
        await bluetooth.writeBytes(Tis620Helper.text(
          "หากลูกค้าชำระล่าช้าหรือเกินกำหนดระยะเวลา 1 เดือน นับตั้งแต่วันที่ลูกค้ารับสินค้าครบถ้วน ทางร้านจะปรับอัตตราดอกเบี้ยขึ้น 8% จากราคาสินค้าต่อเดือน (เฉพาะบิลเครดิต)",
          align: 0 // ชิดซ้ายเพื่อให้ตัดคำอ่านง่ายขึ้นใน Text Mode
        ));
        await bluetooth.printNewLine();


      // พื้นที่เซ็นชื่อ (Text Mode)
      await bluetooth.printNewLine();
      await bluetooth.writeBytes(Tis620Helper.text("................................", align: 1));
      await bluetooth.writeBytes(Tis620Helper.text("ลายเซ็นต์", align: 1));

      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
  }

  // --- โหมดรูปภาพ (Image Mode) [แก้ไขตาม requirement] ---
  Future<void> _printReceiptAsImage(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? customerAddress, 
    String? customerPhone, 
    String? salespersonName, 
    required bool isCredit,
  }) async {
    final GlobalKey receiptKey = GlobalKey();
    double baseFontSize = await preferences.getPrinterFontSize();
    double headerSize = baseFontSize * 1.4;
    double normalSize = baseFontSize;
    double smallSize = baseFontSize * 0.8; 
    // [เพิ่ม] ขนาดตัวอักษรสำหรับ Warning ให้เล็กหน่อยจะได้ไม่กินที่มาก
    double warningSize = baseFontSize * 0.7; 

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

    double totalAmount = 0.0;
    for (var item in cartItems) {
      totalAmount += item.totalSoldPrice;
    }
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

    // Logic คำสั่ง isCredit
    String paymentLabel = isCredit ? "เครดิต" : "เงินสด";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: RepaintBoundary(
              key: receiptKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                width: 380, 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text("BRIGHT MOTOR", style: TextStyle(fontSize: headerSize, fontWeight: FontWeight.bold, color: Colors.black))),
                    Center(child: Text("STORE", style: TextStyle(fontSize: headerSize * 0.8, color: Colors.black))),
                    Divider(color: Colors.black, thickness: 1.5),
                    
                    Text("Date: $dateStr", style: TextStyle(fontSize: normalSize, color: Colors.black)),
                    if (customerName != null) 
                      Text("ลูกค้า: $customerName", style: TextStyle(fontSize: normalSize, fontWeight: FontWeight.bold, color: Colors.black)),
                    
                    if (customerAddress != null && customerAddress.isNotEmpty)
                      Text("ที่อยู่: $customerAddress", style: TextStyle(fontSize: smallSize, color: Colors.black)),
                    if (customerPhone != null && customerPhone.isNotEmpty)
                      Text("โทร: $customerPhone", style: TextStyle(fontSize: smallSize, color: Colors.black)),
                    
                    // [เพิ่ม] แสดงประเภทการชำระเงิน
                    Text("การชำระเงิน: $paymentLabel", style: TextStyle(fontSize: normalSize, color: Colors.black)),
                    if (salespersonName != null)
                      Text("พนักงานขาย: $salespersonName", style: TextStyle(fontSize: normalSize, color: Colors.black)),
                    Divider(color: Colors.black),
                    
                    ...cartItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.description, style: TextStyle(fontSize: normalSize, color: Colors.black)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${item.quantity} x ${item.soldPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: smallSize, color: Colors.black)),
                              Text(_formatCurrency(item.totalSoldPrice), style: TextStyle(fontSize: normalSize, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                          if (item.discountValue > 0) 
                            Text("  (ส่วนลด ${item.discountValue})", style: TextStyle(fontSize: smallSize, fontStyle: FontStyle.italic, color: Colors.black)),
                        ],
                      ),
                    )),
                    
                    Divider(color: Colors.black, thickness: 1.5),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ยอดรวม:", style: TextStyle(fontSize: headerSize, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(_formatCurrency(totalAmount), style: TextStyle(fontSize: headerSize, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    Center(child: Text("ขอบคุณที่ใช้บริการ", style: TextStyle(fontSize: normalSize, color: Colors.black))),
                    SizedBox(height: 10),

                    // QR Code Section
                    if (qrFile != null) ...[
                      SizedBox(height: 10),
                      Center(child: Text("Scan to Pay", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold))),
                      SizedBox(height: 5),
                      Center(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(5),
                          width: 300, // ปรับขนาดตามความเหมาะสม
                          height: 300,
                          child: Image.file(
                            qrFile,
                            fit: BoxFit.cover, 
                            filterQuality: FilterQuality.high, 
                          ),
                        ),
                      ),
                    ],

                    // [เพิ่ม] ข้อความแจ้งเตือนดอกเบี้ย (เฉพาะเครดิต)
                      SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.5),
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          "หากลูกค้าชำระล่าช้าหรือเกินกำหนดระยะเวลา 1 เดือน นับตั้งแต่วันที่ลูกค้ารับสินค้าครบถ้วน ทางร้านจะปรับอัตตราดอกเบี้ยขึ้น 8% จากราคาสินค้าต่อเดือน (เฉพาะบิลเครดิต)",
                          style: TextStyle(fontSize: warningSize*1.3, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),


                    // เส้นจุดไข่ปลาและลายเซ็นต์
                    SizedBox(height: 60), // ระยะห่างสำหรับเซ็น
                    Center(
                      child: Text(
                        "................................................................", 
                        style: TextStyle(
                          fontSize: normalSize, 
                          color: Colors.black, 
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        "ลายเซ็นต์", 
                        style: TextStyle(
                          fontSize: normalSize, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.black
                        )
                      )
                    ),
                    
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // ... ส่วนการ Capture และ Print Image คงเดิม ...
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      Uint8List pngBytes = await _captureWidgetToImage(receiptKey);
      Navigator.of(context).pop(); 

      final img.Image? originalImage = img.decodeImage(pngBytes);
      if (originalImage != null) {
        final img.Image resizedImage = img.copyResize(originalImage, width: 384, interpolation: img.Interpolation.cubic);
        final img.Image bwImage = img.luminanceThreshold(resizedImage, threshold: 0.5);

        await bluetooth.writeBytes(Uint8List.fromList([0x1B, 0x40])); 
        await Future.delayed(const Duration(milliseconds: 200)); 

        int imageHeight = bwImage.height;
        int chunkHeight = 100; 
        
        for (int y = 0; y < imageHeight; y += chunkHeight) {
          int h = (y + chunkHeight > imageHeight) ? (imageHeight - y) : chunkHeight;
          img.Image chunk = img.copyCrop(bwImage, x: 0, y: y, width: bwImage.width, height: h);
          final List<int> chunkBytes = img.encodeJpg(chunk, quality: 100);
          
          bluetooth.printImageBytes(Uint8List.fromList(chunkBytes));
          await Future.delayed(const Duration(milliseconds: 50)); 
        }

        await Future.delayed(const Duration(milliseconds: 1000));
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