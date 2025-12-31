import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/utils/preferences.dart';
import 'package:brightmotor_store/utils/tis620_helper.dart'; // อย่าลืม import ไฟล์นี้
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

  // --- New Helper to create image from widget ---
  Future<Uint8List> _captureWidgetToImage(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0); // Increase pixel ratio for better quality
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print("Error capturing widget: $e");
      rethrow;
    }
  }

  // --- Modified printReceipt to handle Image Mode ---
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

      // Check Preferences for Image Mode
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

  // --- Original Text Printing Logic (Refactored) ---
  Future<void> _printReceiptAsText(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? paymentType,
  }) async {
      // Get saved code page
      int codePage = await preferences.getPrinterCodePage();
      
      // 1. ตั้งค่า Code Page ภาษาไทย
      await bluetooth.writeBytes(Uint8List.fromList([0x1B, 0x74, codePage]));

      final now = DateTime.now();
      final date = "${now.day}/${now.month}/${now.year}";
      final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // --- Header ---
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

        await bluetooth.writeBytes(Tis620Helper.text(item.product.description));
        
        String detailText = "${item.quantity} x ${item.soldPrice.toStringAsFixed(2)}      $priceText";
        if (item.discountValue > 0) detailText += " (ลด)";
        
        await bluetooth.writeBytes(Tis620Helper.text(detailText, align: 0));
      }

      // --- Footer ---
      await bluetooth.writeBytes(Tis620Helper.text("--------------------------------"));
      await bluetooth.writeBytes(Tis620Helper.text("ยอดรวม: ${_formatCurrency(totalAmount)}", isBold: true, align: 2));
      
      await bluetooth.printNewLine();
      await bluetooth.writeBytes(Tis620Helper.text("ขอบคุณที่ใช้บริการ", align: 1));
      await bluetooth.printNewLine();

      // --- QR Code ---
      await _printQrCodeIfExists(context);

      // --- End ---
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
  }

  // --- New Image Printing Logic ---
  Future<void> _printReceiptAsImage(
    BuildContext context,
    List<CartItem> cartItems, {
    String? customerName,
    String? paymentType,
  }) async {
    // Create a GlobalKey to capture the widget
    final GlobalKey receiptKey = GlobalKey();

    // Calculate totals first
    double totalAmount = 0.0;
    for (var item in cartItems) {
      totalAmount += item.totalSoldPrice;
    }

    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}";

    // Build the widget off-screen (using Overlay or a hidden widget in the tree is tricky, 
    // for simplicity we often insert it into the tree temporarily or use a dedicated view. 
    // However, the cleanest way without disrupting UI is to show a Dialog that auto-closes or 
    // renders invisible. Here we will use a dialog approach to render, capture, then print.)
    
    // NOTE: In a real app, you might want to use a more robust background rendering solution.
    // For this example, we show a "Generating Receipt..." dialog which actually contains the receipt widget.
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          // Make it invisible or cover with loading
          backgroundColor: Colors.white, 
          child: SingleChildScrollView(
            child: RepaintBoundary(
              key: receiptKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                width: 350, // Fixed width for printer (approx 58mm)
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text("BRIGHT MOTOR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black))),
                    Center(child: Text("STORE", style: TextStyle(fontSize: 18, color: Colors.black))),
                    Divider(color: Colors.black),
                    Text("Date: $dateStr", style: TextStyle(fontSize: 14, color: Colors.black)),
                    if (customerName != null) Text("ลูกค้า: $customerName", style: TextStyle(fontSize: 14, color: Colors.black)),
                    Divider(color: Colors.black),
                    ...cartItems.map((item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.description, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item.quantity} x ${item.soldPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 12, color: Colors.black)),
                            Text(_formatCurrency(item.totalSoldPrice), style: TextStyle(fontSize: 14, color: Colors.black)),
                          ],
                        ),
                        if (item.discountValue > 0) 
                          Text("  (ส่วนลด ${item.discountValue})", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black)),
                        SizedBox(height: 4),
                      ],
                    )),
                    Divider(color: Colors.black),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ยอดรวม:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(_formatCurrency(totalAmount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    SizedBox(height: 16),
                    Center(child: Text("ขอบคุณที่ใช้บริการ", style: TextStyle(fontSize: 16, color: Colors.black))),
                    SizedBox(height: 16),
                    // Optional: Embed QR code image directly here if needed, 
                    // or print it separately like before. Printing it as part of the image is cleaner.
                    Center(child: Text("Scan to Pay", style: TextStyle(fontSize: 14, color: Colors.black))),
                    // Placeholder for QR - in real app, render the QR image widget here
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Wait a bit for the widget to render
    await Future.delayed(const Duration(milliseconds: 500));

    // Capture the image
    try {
      Uint8List pngBytes = await _captureWidgetToImage(receiptKey);
      
      // Close the dialog
      Navigator.of(context).pop();

      // Resize and Print
      // Use the image library to decode and resize
      final img.Image? originalImage = img.decodeImage(pngBytes);
      if (originalImage != null) {
        // Resize to fit standard 58mm printer width (approx 384 pixels, safe zone 350-370)
        final img.Image resizedImage = img.copyResize(originalImage, width: 370);
        final List<int> printBytes = img.encodeJpg(resizedImage);

        bluetooth.printNewLine();
        bluetooth.printImageBytes(Uint8List.fromList(printBytes));
        
        // Print QR Code separately if it's external file logic (or embed above)
        await _printQrCodeIfExists(context); 

        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.paperCut();
      }
    } catch (e) {
      // Ensure dialog closes on error
      Navigator.of(context).pop(); 
      throw e;
    }
  }

  // --- Existing Helper Methods ---
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
      final path = '${directory.path}/receipt_qrcode.png';
      final file = File(path);

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