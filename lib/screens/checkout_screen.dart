import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/screens/complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CheckoutScreen extends ConsumerWidget {
  final Customer customer;

  const CheckoutScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truck = ref.watch(currentTruckProvider);
    // [แก้ไข] ใช้ cartProvider แบบใหม่ (List<CartItem>)
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartGrandTotalProvider);
    
    // [แก้ไข] ใช้ PaymentTerm จาก Provider
    final paymentTerm = ref.watch(paymentTermProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            // --- รายการสินค้า ---
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("รายการสินค้า", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ...cartItems.map((item) => ListTile(
                            title: Text("${item.product.description} x${item.quantity}"),
                            subtitle: item.useDiscount ? const Text("ส่วนลด 10%", style: TextStyle(color: Colors.green, fontSize: 12)) : null,
                            trailing: Text("฿${item.totalSoldPrice.toStringAsFixed(2)}"),
                          )),
                          const Divider(),
                          ListTile(
                            title: const Text("ยอดรวมสุทธิ", style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text(
                              "฿${totalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- เลือกช่องทางการชำระเงิน ---
            SliverPadding(
              padding: const EdgeInsets.only(top: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ช่องทางการชำระเงิน", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _PaymentOption(
                      title: "เงินสด",
                      value: PaymentTerm.cash,
                      groupValue: paymentTerm,
                      onChanged: (val) => ref.read(paymentTermProvider.notifier).state = val!,
                    ),
                    _PaymentOption(
                      title: "เครดิตรายเดือน",
                      value: PaymentTerm.monthly,
                      groupValue: paymentTerm,
                      onChanged: (val) => ref.read(paymentTermProvider.notifier).state = val!,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              if (truck == null || truck.truckId == null) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ไม่พบข้อมูลรถ")));
                 return;
              }

              try {
                // [แก้ไข] เรียก submit แบบใหม่ (ไม่ต้องส่ง isCredit หรือ items เองแล้ว)
                await ref.read(cartProvider.notifier).submit(
                  truckId: truck.truckId!,
                  customerId: customer.id,
                );
                
                if (context.mounted) {
                  // ส่ง cartItems ไปให้หน้า Complete (ก่อนจะถูก clear)
                  await launchCheckoutCompleteScreen(context, cartItems, customer.name); 
                  ref.read(cartProvider.notifier).clear(); // ล้างตะกร้าหลังจบ
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("ยืนยันการชำระเงิน", style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final PaymentTerm value;
  final PaymentTerm groupValue;
  final Function(PaymentTerm?) onChanged;

  const _PaymentOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<PaymentTerm>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }
}