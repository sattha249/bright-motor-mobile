import 'package:brightmotor_store/providers/pre_order_provider.dart';
import 'package:brightmotor_store/screens/dialogs/pre_order_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart'; // Import intl ตรงนี้

class PreOrderScreen extends ConsumerWidget {
  const PreOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preOrders = ref.watch(preOrderProvider);
    final notifier = ref.read(preOrderProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("คำสั่งซื้อล่วงหน้า")),
      body: preOrders.isEmpty && notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : preOrders.isEmpty
              ? const Center(child: Text("ไม่มีคำสั่งซื้อ"))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: preOrders.length + (notifier.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == preOrders.length) {
                      Future.microtask(() => notifier.fetchNextPage());
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator()));
                    }

                    final item = preOrders[index];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                PreOrderDetailDialog(preOrderId: item.id),
                          );
                        },
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // [แก้ไข] ห่อ Text ด้วย Expanded เพื่อให้ยืดหยุ่นใน Row
                            Expanded(
                              child: Text(
                                item.billNo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow:
                                    TextOverflow.ellipsis, // ถ้าล้นให้ขึ้น ...
                              ),
                            ),
                            const SizedBox(width: 8), // เว้นระยะห่างนิดนึง
                            _buildStatusBadge(item.status),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("ลูกค้า: ${item.customer.name}"),
                            // ใช้ DateFormat ตรงนี้
                            Text(
                                "วันที่: ${item.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!) : '-'}"),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "฿${item.totalSoldPrice}",
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            Text(item.isCredit == 'cash' ? "เงินสด" : "เครดิต",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'Pending') color = Colors.orange;
    if (status == 'Completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
