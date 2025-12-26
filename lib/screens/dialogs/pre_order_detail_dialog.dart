import 'package:brightmotor_store/models/pre_order_model.dart';
import 'package:brightmotor_store/services/pre_order_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PreOrderDetailDialog extends ConsumerWidget {
  final int preOrderId;

  const PreOrderDetailDialog({super.key, required this.preOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600), // จำกัดความสูง
        child: FutureBuilder<PreOrder>(
          future: ref.read(preOrderServiceProvider).getPreOrderDetail(preOrderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text("Error: ${snapshot.error}"),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("ปิด"))
                  ],
                ),
              );
            }

            final order = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("รายละเอียดคำสั่งซื้อ", style: Theme.of(context).textTheme.titleLarge),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content (Scrollable)
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    children: [
                      _buildInfoRow("เลขที่บิล", order.billNo),
                      _buildInfoRow("ลูกค้า", order.customer.name),
                      _buildInfoRow("เบอร์โทร", order.customer.tel),
                      _buildInfoRow("สถานะ", order.status),
                      const SizedBox(height: 16),
                      const Text("รายการสินค้า:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      
                      // List of Items
                      if (order.items.isEmpty)
                        const Text("- ไม่พบรายการสินค้า -", style: TextStyle(color: Colors.grey)),
                      
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text("x${item.quantity}"),
                            const SizedBox(width: 16),
                            Text("฿${item.total}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("ยอดรวมสุทธิ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("฿${order.totalSoldPrice}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("ปิด"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement confirm logic here
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("ยืนยันรายการแล้ว")),
                            );
                          },
                          child: const Text("ยืนยัน"),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}