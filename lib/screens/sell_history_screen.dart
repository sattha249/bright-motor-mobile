import 'package:brightmotor_store/models/cart_model.dart'; // import CartItem
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/printer/print_service.dart';
import 'package:brightmotor_store/services/sale_history_service.dart'; // Import ไฟล์ service
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

// สร้าง FutureProvider สำหรับ UI เรียกใช้ โดยผ่าน Service อีกที
final sellLogsListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final truck = ref.watch(currentTruckProvider);
  if (truck?.truckId == null) return [];

  // เรียกใช้ Service ผ่าน Provider
  final service = ref.read(sellHistoryServiceProvider);
  return service.getSellLogs(truckId: truck!.truckId!);
});

class SellHistoryScreen extends ConsumerWidget {
  const SellHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // เปลี่ยนมา watch ตัว list provider
    final asyncLogs = ref.watch(sellLogsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ประวัติการขาย"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(sellLogsListProvider),
          )
        ],
      ),
      body: asyncLogs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text("ไม่พบประวัติการขาย"));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('เวลา')),
                  DataColumn(label: Text('ลูกค้า')),
                  DataColumn(label: Text('ยอดเงิน', textAlign: TextAlign.right)),
                  DataColumn(label: Text('พิมพ์')),
                ],
                rows: logs.map((log) {
                  return _buildDataRow(context, ref, log); // ส่ง ref เข้าไป
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, WidgetRef ref, dynamic log) {
    final dateStr = log['created_at'] ?? '';
    final dateDisplay = dateStr.isNotEmpty
        ? DateFormat('dd/MM HH:mm').format(DateTime.parse(dateStr))
        : '-';

    final customerName = log['customer']['name'] ?? 'ทั่วไป';
    final total = double.tryParse(log['total_price'].toString()) ?? 0.0;

    return DataRow(cells: [
      DataCell(Text(dateDisplay)),
      DataCell(Text(customerName)),
      DataCell(Text(
        "฿${total.toStringAsFixed(2)}",
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      )),
      DataCell(
        IconButton(
          icon: const Icon(Icons.print, color: Colors.blue),
          onPressed: () => _rePrint(context, ref, log),
        ),
      ),
    ]);
  }

  Future<void> _rePrint(BuildContext context, WidgetRef ref, dynamic logData) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กำลังเตรียมข้อมูลพิมพ์...")));

      final itemsRaw = logData['items'] as List<dynamic>? ?? [];
      
      // เรียกใช้ Helper Function ผ่าน Service Provider
      final service = ref.read(sellHistoryServiceProvider);
      final itemsToPrint = service.convertLogToCartItems(itemsRaw);

      if (itemsToPrint.isEmpty) throw Exception("ไม่พบรายการสินค้าในบิลนี้");
      print(logData);
      await PrintService().printReceipt(
        context,
        itemsToPrint,
        customerName: logData['customer']['name'],
      );

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}