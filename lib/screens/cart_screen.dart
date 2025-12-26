import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/screens/complete_screen.dart'; // import หน้า Complete
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CartScreen extends ConsumerWidget {
  final Customer customer;

  const CartScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    
    final paymentTerm = ref.watch(paymentTermProvider);
    final totalAmount = ref.watch(cartGrandTotalProvider);

    final isCreditMode = paymentTerm != PaymentTerm.cash;

    return Scaffold(
      appBar: AppBar(
        title: Text('ตะกร้าสินค้า - ${customer.name}'),
      ),
      body: Column(
        children: [
          // --- Payment Term ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Text("ชำระเงิน: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PaymentTerm>(
                      value: paymentTerm,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: PaymentTerm.cash, child: Text("เงินสด (Cash)")),
                        DropdownMenuItem(value: PaymentTerm.weekly, child: Text("เครดิต 1 สัปดาห์")),
                        DropdownMenuItem(value: PaymentTerm.monthly, child: Text("เครดิต 1 เดือน")),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(paymentTermProvider.notifier).state = value;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Product List ---
          Expanded(
            child: cartItems.isEmpty 
            ? const Center(child: Text("ไม่มีสินค้าในตะกร้า"))
            : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: cartItems.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.product.description),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${item.quantity} x ${item.product.sellPrice} = ฿${(item.quantity * item.price).toStringAsFixed(2)}"),
                              if (item.discountValue > 0)
                                Text(
                                  "ส่วนลด: -฿${item.totalDiscount.toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // แสดงราคาสุทธิ
                              Text(
                                "฿${item.totalSoldPrice.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => notifier.removeItem(item.product),
                              ),
                            ],
                          ),
                        ),
                        
                        // Checkbox (เฉพาะเครดิต)
                        if (isCreditMode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text("จ่ายแล้ว"),
                              Checkbox(
                                value: item.isPaid,
                                onChanged: (val) {
                                  notifier.togglePaid(index, val ?? false);
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- Discount Buttons (Global) ---
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text("ส่วนลด: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  _DiscountButton(label: "0%", onPressed: () => notifier.clearDiscount()),
                  const SizedBox(width: 8),
                  _DiscountButton(label: "5%", onPressed: () => notifier.applyPercentDiscount(5)),
                  const SizedBox(width: 8),
                  _DiscountButton(label: "10%", onPressed: () => notifier.applyPercentDiscount(10)),
                  const SizedBox(width: 8),
                  _DiscountButton(label: "15%", onPressed: () => notifier.applyPercentDiscount(15)),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text("ระบุเอง"),
                    backgroundColor: Colors.orange.shade100,
                    onPressed: () {
                      _showCustomDiscountDialog(context, notifier);
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Bottom Bar ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ยอดสุทธิ", style: TextStyle(color: Colors.grey)),
                    Text(
                      "฿${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: cartItems.isEmpty ? null : () async {
                    try {
                        final truck = ref.read(currentTruckProvider);
                        if (truck == null || truck.truckId == null) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("ไม่พบข้อมูลรถ (Truck ID Missing)"), backgroundColor: Colors.red)
                           );
                           return;
                        }

                        // บันทึกการขาย
                        await notifier.submit(
                          truckId: truck.truckId!, 
                          customerId: customer.id
                        );
                        
                        if (context.mounted) {
                          // [แก้ไข] 1. ไปหน้า Complete ก่อน (ส่ง list ที่ clone ไว้ หรือดึงจาก provider ในหน้าถัดไปก็ได้ แต่ส่งไปชัวร์สุด)
                          final soldItems = List<CartItem>.from(cartItems); // Clone ไว้ก่อน clear
                          await launchCheckoutCompleteScreen(context, soldItems);
                          
                          // [แก้ไข] 2. พอกลับมาจากหน้า Complete (หรือกดปิดในหน้านั้น) ค่อยเคลียร์
                          notifier.clear(); 
                          
                          // [แก้ไข] 3. กลับไปหน้าแรกสุด (Home) หรือหน้าที่ต้องการ
                          // Navigator.pop(context); // อันนี้จะกลับไป CategoryScreen
                          // ถ้าอยากกลับไปหน้า Home เลยให้ใช้ popUntil
                          // Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                    } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                        }
                    }
                  },
                  child: const Text("ยืนยันการขาย", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomDiscountDialog(BuildContext context, CartNotifier notifier) {
    final controller = TextEditingController();
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("ส่วนลด (บาท)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "กรอกจำนวนเงินที่ต้องการลด"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                notifier.applyFixedDiscount(amount);
              }
              Navigator.pop(context);
            }, 
            child: const Text("ตกลง")
          ),
        ],
      )
    );
  }
}

class _DiscountButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _DiscountButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
    );
  }
}