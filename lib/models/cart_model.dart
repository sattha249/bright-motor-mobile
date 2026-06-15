import 'package:brightmotor_store/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  double discountValue; // [แก้ไข] เก็บค่าส่วนลดเป็นตัวเลข (ต่อชิ้น)
  bool isPaid;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discountValue = 0.0,
    this.isPaid = false,
  });

  double get price => double.tryParse(product.sellPrice) ?? 0.0;

  // ส่วนลดต่อชิ้น (ดึงจากตัวแปรตรงๆ)
  double get discountAmount => discountValue;

  // ราคาขายจริงต่อชิ้น (ราคาตั้ง - ส่วนลด)
  double get soldPrice => price - discountAmount;

  double get totalSoldPrice => soldPrice * quantity;
  
  double get totalDiscount => discountAmount * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? discountValue,
    bool? isPaid,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountValue: discountValue ?? this.discountValue,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  /// ย้อนเศษส่วนลดเฉลี่ยจากการปัดทศนิยมของ Database เพื่อคืนค่าส่วนลดรวมดั้งเดิมที่ถูกต้อง
  static double reconstructDiscountValue(double dUnit, int qty) {
    if (dUnit <= 0 || qty <= 0) return dUnit;

    final double calculatedTotal = dUnit * qty;

    // 1. ลองจำนวนเต็ม (e.g. 7.00, 15.00)
    final int nearestInt = calculatedTotal.round();
    if ((nearestInt / qty - dUnit).abs() <= 0.0051) {
      return nearestInt / qty;
    }

    // 2. ลองลงท้าย .50 (e.g. 7.50)
    final double nearestHalf = (calculatedTotal * 2).round() / 2;
    if ((nearestHalf / qty - dUnit).abs() <= 0.0051) {
      return nearestHalf / qty;
    }

    // 3. ลองลงท้าย .10 (e.g. 7.20)
    final double nearestTenth = (calculatedTotal * 10).round() / 10;
    if ((nearestTenth / qty - dUnit).abs() <= 0.0051) {
      return nearestTenth / qty;
    }

    // 4. ลองลงท้าย .05 (e.g. 7.25)
    final double nearestTwentieth = (calculatedTotal * 20).round() / 20;
    if ((nearestTwentieth / qty - dUnit).abs() <= 0.0051) {
      return nearestTwentieth / qty;
    }

    return dUnit;
  }
}