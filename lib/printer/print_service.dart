import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:brightmotor_store/models/product_model.dart';

class PrintService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<void> testPrinter() async {
    if ((await bluetooth.isConnected) ?? false) {
      bluetooth.printNewLine();
      bluetooth.printCustom("Test Print", 2, 1); // Large centered text
      bluetooth.printNewLine();
      bluetooth.printCustom("This is a test print.", 1, 0);
      bluetooth.printNewLine();
      bluetooth.paperCut(); // Cut paper if printer supports it
    } else {
      throw Exception("Printer is not connected");
    }
  }

  Future<void> printReceipt(Map<Product, int> productWithQuantity) async {
    final now = DateTime.now();
    final date = "${now.year}-${now.month}-${now.day}";
    final time = "${now.hour}:${now.minute}";

    if ((await bluetooth.isConnected) ?? false) {
      bluetooth.printNewLine();
      bluetooth.printCustom("STORE NAME", 2, 1); // Large centered text
      bluetooth.printNewLine();
      bluetooth.printLeftRight("Date:", date, 1);
      bluetooth.printLeftRight("Time:", time, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Items Purchased", 1, 0);
      var total = 0.0;
      for (var entry in productWithQuantity.entries) {
        final product = entry.key;
        final quantity = entry.value;
        final price = double.parse(product.sellPrice) * quantity;
        total += price;
        final priceText = price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
        bluetooth.printLeftRight(
          "${product.description} x $quantity",
          priceText,
          1,
        );
      }
      final totalText = total.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      bluetooth.printLeftRight("Total", totalText, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Thank You!", 2, 1);
      bluetooth.printNewLine();
      bluetooth.paperCut(); // Cut paper if printer supports it
    }
  }
}
