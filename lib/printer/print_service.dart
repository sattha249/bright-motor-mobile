import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/models/cart_model.dart'; // [แก้ไข] ใช้ CartItem แทน Product Model เดิม

class PrintService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

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
  Future<void> printReceipt(List<CartItem> cartItems, {String? customerName, String? paymentType}) async {
    final now = DateTime.now();
    // จัดรูปแบบวันเวลาแบบง่ายๆ (หรือจะใช้ intl DateFormat ก็ได้)
    final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    if ((await bluetooth.isConnected) ?? false) {
      // --- Header ---
      bluetooth.printNewLine();
      bluetooth.printCustom("BRIGHT MOTOR", 3, 1); // ชื่อร้านใหญ่ๆ
      bluetooth.printCustom("STORE", 1, 1);
      bluetooth.printNewLine();
      
      bluetooth.printLeftRight("Date:", "$date $time", 1);
      if (customerName != null) {
        bluetooth.printLeftRight("Customer:", customerName, 1);
      }
      if (paymentType != null) {
        bluetooth.printLeftRight("Payment:", paymentType, 1);
      }
      
      bluetooth.printCustom("--------------------------------", 1, 1);

      // --- Items ---
      double totalAmount = 0.0;

      for (var item in cartItems) {
        // คำนวณยอดรวมของรายการนี้ (ราคาหลังหักส่วนลด * จำนวน)
        final itemTotal = item.totalSoldPrice;
        totalAmount += itemTotal;

        // จัดรูปแบบตัวเลขให้มีคอมม่า (e.g. 1,200.00)
        final priceText = _formatCurrency(itemTotal);

        // บรรทัดที่ 1: ชื่อสินค้า
        bluetooth.printCustom(item.product.description, 1, 0);
        
        // บรรทัดที่ 2: จำนวน x ราคาต่อหน่วย ... ราคารวม
        // ถ้ามีส่วนลด อาจจะวงเล็บไว้หน่อย
        String detailText = "${item.quantity} x ${item.soldPrice.toStringAsFixed(2)}";
        if (item.discountValue > 0) {
           detailText += " (Disc.)";
        }
        
        bluetooth.printLeftRight(detailText, priceText, 1);
      }

      // --- Footer ---
      bluetooth.printCustom("--------------------------------", 1, 1);
      
      final totalText = _formatCurrency(totalAmount);
      bluetooth.printLeftRight("TOTAL", totalText, 3); // Total ใหญ่หน่อย (Size 3)
      
      bluetooth.printNewLine();
      bluetooth.printCustom("Thank You!", 2, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut(); 
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