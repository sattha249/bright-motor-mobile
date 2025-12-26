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

  void addItem(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final oldItem = state[existingIndex];
      final newItem = oldItem.copyWith(quantity: oldItem.quantity + 1);
      state = [...state.sublist(0, existingIndex), newItem, ...state.sublist(existingIndex + 1)];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
    // หมายเหตุ: เมื่อเพิ่มสินค้า อาจจะต้อง Reset ส่วนลดหรือไม่? 
    // ปกติถ้าเพิ่มของ ยอดเปลี่ยน ส่วนลดแบบระบุจำนวนเงินอาจเพี้ยน แต่ % ยังได้อยู่
    // ในที่นี้ขอคงค่าส่วนลดเดิมไว้ก่อน
  }

  void removeItem(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final oldItem = state[existingIndex];
      if (oldItem.quantity > 1) {
        final newItem = oldItem.copyWith(quantity: oldItem.quantity - 1);
        state = [...state.sublist(0, existingIndex), newItem, ...state.sublist(existingIndex + 1)];
      } else {
        state = [...state]..removeAt(existingIndex);
      }
    }
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
      // คำนวณส่วนลดต่อชิ้น
      final discountPerItem = item.price * (percent / 100);
      return item.copyWith(discountValue: discountPerItem);
    }).toList();
  }

  // 2. ใช้ส่วนลดแบบระบุจำนวนเงิน (กระจายตามสัดส่วนราคาสินค้า)
  void applyFixedDiscount(double totalDiscountAmount) {
    // หายอดรวมราคาตั้งต้น (ก่อนลด) ของทั้งตะกร้า
    double totalOriginalPrice = state.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

    if (totalOriginalPrice == 0) return;

    state = state.map((item) {
      // สัดส่วนมูลค่าของสินค้านี้ ต่อ ยอดรวมทั้งหมด
      // (ราคาต่อชิ้น / ราคารวมทั้งหมด) * ยอดส่วนลดรวม
      // สูตรนี้จะได้ส่วนลด "ต่อ 1 ชิ้น"
      
      // ตัวอย่าง: ของ A ราคา 100 มี 2 ชิ้น (มูลค่า 200), ของ B ราคา 800 มี 1 ชิ้น (มูลค่า 800). รวม 1000.
      // ส่วนลด 100 บาท.
      // Item A (ต่อชิ้น) discount = (100 / 1000) * 100 = 10 บาท.
      
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