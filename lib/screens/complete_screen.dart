import 'package:brightmotor_store/models/cart_model.dart'; // import CartItem
import 'package:brightmotor_store/printer/print_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// [แก้ไข] เพิ่มการรับค่า billNo และ isPreorder
Future<dynamic> launchCheckoutCompleteScreen(
  BuildContext context,
  List<CartItem> items,
  String? customerName, {
  bool isCredit = false,
  String? customerAddress,
  String? customerPhone,
  String? salespersonName,
  String? billNo, // [เพิ่ม]
  bool isPreorder = false, // [เพิ่ม]
  double? totalSoldPrice,
  double? totalDiscount,
}) {
  return Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CompleteScreen(
            items: items,
            customerName: customerName,
            isCredit: isCredit,
            customerAddress: customerAddress,
            customerPhone: customerPhone,
            salespersonName: salespersonName,
            billNo: billNo, // [เพิ่ม] ส่งต่อให้ Widget
            isPreorder: isPreorder, // [เพิ่ม] ส่งต่อให้ Widget
            totalSoldPrice: totalSoldPrice,
            totalDiscount: totalDiscount,
          ),
      fullscreenDialog: true));
}

class CompleteScreen extends ConsumerWidget {
  final List<CartItem> items;
  final String? customerName;
  final bool isCredit;
  final String? customerAddress;
  final String? customerPhone;
  final String? salespersonName;
  final String? billNo; // [เพิ่ม]
  final bool isPreorder; // [เพิ่ม]
  final double? totalSoldPrice;
  final double? totalDiscount;

  const CompleteScreen({
    super.key,
    required this.items,
    this.customerName,
    required this.isCredit,
    this.customerAddress,
    this.customerPhone,
    this.salespersonName,
    this.billNo, // [เพิ่ม]
    this.isPreorder = false, // [เพิ่ม]
    this.totalSoldPrice,
    this.totalDiscount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false), // ปิดปุ่ม back
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              'ชำระเงินสำเร็จ!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text("บันทึกข้อมูลเรียบร้อยแล้ว",
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('ปิด'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // [แก้ไข] ส่ง billNo และ isPreorder ทะลุไปให้ PrintService
                    PrintService().printReceipt(
                      context,
                      items,
                      customerName: customerName,
                      customerAddress: customerAddress,
                      customerPhone: customerPhone,
                      salespersonName: salespersonName,
                      isCredit: isCredit,
                      billNo: billNo, // [เพิ่ม]
                      isPreorder: isPreorder, // [เพิ่ม]
                      totalSoldPrice: totalSoldPrice,
                      totalDiscount: totalDiscount,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("ส่งคำสั่งพิมพ์...")));
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('พิมพ์ใบเสร็จ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
