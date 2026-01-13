import 'package:brightmotor_store/models/cart_model.dart'; // import CartItem
import 'package:brightmotor_store/printer/print_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// [แก้ไข] รับ items เข้ามาทาง Constructor
Future<dynamic> launchCheckoutCompleteScreen(BuildContext context, List<CartItem> items, String? customerName) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CompleteScreen(items: items, customerName: customerName), 
      fullscreenDialog: true
    )
  );
}

class CompleteScreen extends ConsumerWidget {
  final List<CartItem> items; // [เพิ่ม] รับรายการสินค้าที่ขายไปแล้ว
  final String? customerName;
  const CompleteScreen({super.key, required this.items,this.customerName});

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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text("บันทึกข้อมูลเรียบร้อยแล้ว", style: TextStyle(color: Colors.grey[600])),
            
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
                    PrintService().printReceipt(context, items,customerName: customerName);
                    // [แก้ไข] ส่ง items ไปพิมพ์ (PrintService ต้องรองรับ List<CartItem>)
                    // PrintService().printReceipt(items); 
                    
                    // หมายเหตุ: คุณต้องไปแก้ PrintService ให้รับ List<CartItem> ด้วยนะครับ
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ส่งคำสั่งพิมพ์...")));
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