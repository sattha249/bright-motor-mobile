import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/screens/complete_screen.dart'; // import หน้า Complete
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final truck = ref.watch(currentTruckProvider);
    final salespersonName = truck?.fullName ?? '-';

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
                return _CartItemCard(
                  item: item,
                  index: index,
                  isCreditMode: isCreditMode,
                  notifier: notifier,
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
                      // ✅ 1. เด้งหน้าต่าง Loading บังหน้าจอไว้ทันทีที่กดปุ่ม
                      showDialog(
                        context: context,
                        barrierDismissible: false, // บังคับไม่ให้กดพื้นที่ว่างเพื่อปิด
                        builder: (ctx) => const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("กำลังบันทึกข้อมูล..."),
                            ],
                          ),
                        ),
                      );

                      try {
                          final truck = ref.read(currentTruckProvider);
                          if (truck == null || truck.truckId == null) {
                             Navigator.pop(context); // ปิด Loading ก่อนแจ้งเตือน
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("ไม่พบข้อมูลรถ (Truck ID Missing)"), backgroundColor: Colors.red)
                             );
                             return;
                          }

                          // ✅ 2. ยิง API
                          final billNo = await notifier.submit(
                            truckId: truck.truckId!, 
                            customerId: customer.id
                          );
                          
                          if (context.mounted) {
                            Navigator.pop(context); // ✅ 3. ปิด Loading เมื่อทำงานสำเร็จ!

                            final soldItems = List<CartItem>.from(cartItems);
                            
                            await launchCheckoutCompleteScreen(
                              context, 
                              soldItems, 
                              customer.name,
                              isCredit: isCreditMode, 
                              customerAddress: customer.address, 
                              customerPhone: customer.tel,     
                              salespersonName: salespersonName,
                              billNo: billNo,         
                              isPreorder: false,      
                            );
                            
                            notifier.clear(); 
                          }
                      } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // ✅ 4. ปิด Loading ถ้าเกิด Error เพื่อให้กดลองใหม่ได้
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                            );
                          }
                      }
                    },
                    child: const Text("ยืนยันการขาย", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),],
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

void _showDeleteConfirmDialog(BuildContext context, CartNotifier notifier, CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณต้องการลบสินค้า '${item.product.description}' ออกจากตะกร้าทั้งหมดหรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // ปิด Dialog
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // ลบสินค้าชิ้นนั้นทั้งหมด (Logic เดิม)
              notifier.removeItem(item.product);
              Navigator.pop(context); // ปิด Dialog
            },
            child: const Text("ลบทั้งหมด", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

class _CartItemCard extends ConsumerStatefulWidget {
  final CartItem item;
  final int index;
  final bool isCreditMode;
  final CartNotifier notifier;

  const _CartItemCard({
    required this.item,
    required this.index,
    required this.isCreditMode,
    required this.notifier,
  });

  @override
  ConsumerState<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<_CartItemCard> {
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    final totalDiscount = widget.item.discountValue * widget.item.quantity;
    _discountController = TextEditingController(
      text: totalDiscount == 0 ? '' : totalDiscount.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant _CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentTotalDiscount = widget.item.discountValue * widget.item.quantity;
    final oldTotalDiscount = oldWidget.item.discountValue * oldWidget.item.quantity;
    if (currentTotalDiscount != oldTotalDiscount) {
      final currentTextVal = double.tryParse(_discountController.text) ?? 0.0;
      if ((currentTextVal - currentTotalDiscount).abs() > 0.01) {
        _discountController.text = currentTotalDiscount == 0
            ? ''
            : currentTotalDiscount.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(widget.item.product.description),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.item.quantity} x ${widget.item.product.sellPrice} = ฿${(widget.item.quantity * widget.item.price).toStringAsFixed(2)}",
                  ),
                  if (widget.item.discountValue > 0)
                    Text(
                      "ส่วนลดรวม: -฿${widget.item.totalDiscount.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // แสดงราคาสุทธิ
                  Text(
                    "฿${widget.item.totalSoldPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 4), // เว้นระยะนิดนึง

                  // ปุ่มลบ/ลดจำนวน
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20), // ให้ Effect เป็นวงกลม
                      onTap: () {
                        widget.notifier.decreaseItem(widget.item.product);
                      },
                      onLongPress: () {
                        _showDeleteConfirmDialog(context, widget.notifier, widget.item);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.delete, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // input สำหรับ ส่วนลดรวมของรายการสินค้า
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        "ส่วนลดรวมรายการ:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("฿ ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 100,
                        height: 36,
                        child: TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: "0.00",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                          onChanged: (val) {
                            final double totalLineDiscount = double.tryParse(val) ?? 0.0;
                            final maxAllowedDiscount = widget.item.price * widget.item.quantity;
                            if (totalLineDiscount > maxAllowedDiscount) {
                              widget.notifier.updateItemDiscount(widget.item.product, maxAllowedDiscount);
                              _discountController.text = maxAllowedDiscount.toStringAsFixed(2);
                              _discountController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _discountController.text.length),
                              );
                            } else {
                              widget.notifier.updateItemDiscount(widget.item.product, totalLineDiscount);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Checkbox (เฉพาะเครดิต)
            if (widget.isCreditMode) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("จ่ายแล้ว"),
                  Checkbox(
                    value: widget.item.isPaid,
                    onChanged: (val) {
                      widget.notifier.togglePaid(widget.index, val ?? false);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}