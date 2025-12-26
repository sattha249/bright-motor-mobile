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
}