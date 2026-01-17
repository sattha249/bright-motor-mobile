import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/sell_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum PaymentTerm { cash, weekly, monthly }

final paymentTermProvider = StateProvider.autoDispose<PaymentTerm>((ref) => PaymentTerm.cash);

final cartProvider = StateNotifierProvider.autoDispose<CartNotifier, List<CartItem>>((ref) {
  final sellService = ref.read(sellServiceProvider);
  return CartNotifier(sellService, ref);
});

final cartItemCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});

final cartGrandTotalProvider = Provider.autoDispose<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.totalSoldPrice);
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final SellService sellService;
  final Ref ref;

  CartNotifier(this.sellService, this.ref) : super([]);

  // [แก้ไข 1] เพิ่ม parameter quantity ให้รับค่าจำนวนได้ (default = 1)
  // เพื่อรองรับการวนลูปเพิ่ม หรือสั่งเพิ่มทีเดียวหลายชิ้น
  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final oldItem = state[existingIndex];
      // บวกเพิ่มตาม quantity ที่ส่งมา
      final newItem = oldItem.copyWith(quantity: oldItem.quantity + quantity);
      state = [...state.sublist(0, existingIndex), newItem, ...state.sublist(existingIndex + 1)];
    } else {
      // สร้างรายการใหม่ตาม quantity ที่ส่งมา
      state = [...state, CartItem(product: product, quantity: quantity)];
    }
  }

  // [เพิ่มใหม่ 2] ฟังก์ชันลดจำนวนทีละ 1 (สำหรับ Single Tap)
  void decreaseItem(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final oldItem = state[existingIndex];
      if (oldItem.quantity > 1) {
        // ถ้ามีมากกว่า 1 ให้ลดลง 1
        final newItem = oldItem.copyWith(quantity: oldItem.quantity - 1);
        state = [...state.sublist(0, existingIndex), newItem, ...state.sublist(existingIndex + 1)];
      } else {
        // ถ้าเหลือ 1 แล้วกดลด ให้ลบออกจากตะกร้าเลย
        state = [...state]..removeAt(existingIndex);
      }
    }
  }

  // [แก้ไข 3] เปลี่ยนหน้าที่เป็น "ลบทั้งหมด" (สำหรับ Long Press หรือปุ่ม Delete ในหน้า ProductSearch)
  void removeItem(Product product) {
    // ลบสินค้านั้นออกจาก List ทันที ไม่สน quantity
    state = state.where((item) => item.product.id != product.id).toList();
  }

  void togglePaid(int index, bool value) {
    final item = state[index];
    final newItem = item.copyWith(isPaid: value);
    state = [...state.sublist(0, index), newItem, ...state.sublist(index + 1)];
  }

  // --- Logic ส่วนลดใหม่ ---

  // 1. ใช้ส่วนลดแบบเปอร์เซ็นต์ (Apply กับทุกชิ้น)
  void applyPercentDiscount(double percent) {
    state = state.map((item) {
      final discountPerItem = item.price * (percent / 100);
      return item.copyWith(discountValue: discountPerItem);
    }).toList();
  }

  // 2. ใช้ส่วนลดแบบระบุจำนวนเงิน (กระจายตามสัดส่วนราคาสินค้า)
  void applyFixedDiscount(double totalDiscountAmount) {
    double totalOriginalPrice = state.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

    if (totalOriginalPrice == 0) return;

    state = state.map((item) {
      final discountPerItem = (item.price / totalOriginalPrice) * totalDiscountAmount;
      return item.copyWith(discountValue: discountPerItem);
    }).toList();
  }

  // ล้างส่วนลด
  void clearDiscount() {
    state = state.map((item) => item.copyWith(discountValue: 0.0)).toList();
  }

  // ----------------------

  void clear() {
    state = [];
  }

  Future<void> submit({required int truckId, required int customerId}) async {
    final paymentTerm = ref.read(paymentTermProvider);
    await sellService.submitOrder(
      truckId: truckId,
      customerId: customerId,
      paymentTerm: paymentTerm,
      items: state,
    );
  }
}