import 'package:brightmotor_store/models/cart_model.dart'; // import CartItem
import 'package:brightmotor_store/printer/print_service.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/services/sell_history_service.dart'; // ตรวจสอบ path ให้ถูกต้อง
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

// 1. Provider เก็บเลขหน้าปัจจุบัน (เริ่มที่หน้า 1)
final sellHistoryPageProvider = StateProvider.autoDispose<int>((ref) => 1);

// 2. Provider ดึงข้อมูล (รับค่าเป็น Map เพื่อเอา meta data)
final sellLogsResultProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final truck = ref.watch(currentTruckProvider);
  final page = ref.watch(sellHistoryPageProvider); // ฟังค่าเลขหน้า ถ้าเปลี่ยนจะโหลดใหม่

  if (truck?.truckId == null) return {};

  final service = ref.read(sellHistoryServiceProvider);
  
  // เรียก Service ที่เราแก้ไปเมื่อกี้ (return Map)
  return service.getSellLogs(truckId: truck!.truckId!, page: page);
});

class SellHistoryScreen extends ConsumerWidget {
  const SellHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(sellLogsResultProvider);
    final currentPage = ref.watch(sellHistoryPageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ประวัติการขาย"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(sellLogsResultProvider),
          )
        ],
      ),
      body: asyncResult.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (result) {
          // แกะข้อมูลจาก Map
          final logs = result['data'] as List<dynamic>? ?? [];
          final meta = result['meta'] as Map<String, dynamic>? ?? {};

          if (logs.isEmpty && currentPage == 1) {
            return const Center(child: Text("ไม่พบประวัติการขาย"));
          }

          // ข้อมูลสำหรับ Pagination
          final lastPage = meta['last_page'] as int? ?? 1;
          final total = meta['total'] as int? ?? 0;

          return Column(
            children: [
              // --- ส่วนตารางรายการ ---
              Expanded(
                child: SingleChildScrollView(
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
                        return _buildDataRow(context, ref, log);
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // --- ส่วนปุ่มเปลี่ยนหน้า (Pagination) ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2), 
                      blurRadius: 4, 
                      offset: const Offset(0, -2)
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ปุ่มย้อนกลับ
                    ElevatedButton.icon(
                      onPressed: currentPage > 1
                          ? () => ref.read(sellHistoryPageProvider.notifier).state--
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text("ก่อนหน้า"),
                    ),

                    // แสดงเลขหน้า
                    Column(
                      children: [
                        Text("หน้า $currentPage / $lastPage", 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("รวม $total รายการ", 
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),

                    // ปุ่มถัดไป
                    ElevatedButton(
                      onPressed: currentPage < lastPage
                          ? () => ref.read(sellHistoryPageProvider.notifier).state++
                          : null,
                      child: Row(
                        children: const [
                          Text("ถัดไป"),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- สร้างแถวในตาราง ---
 DataRow _buildDataRow(BuildContext context, WidgetRef ref, dynamic log) {
    final dateStr = log['created_at'] ?? '';
    final dateDisplay = dateStr.isNotEmpty
        ? DateFormat('dd/MM HH:mm').format(DateTime.parse(dateStr))
        : '-';

    final customerName = log['customer']?['name'] ?? 'ทั่วไป';
    // [เพิ่ม] แปลงยอดเงินให้เป็น double ที่ถูกต้อง
    final total = double.tryParse(log['total_sold_price'].toString()) ?? 
                  double.tryParse(log['total_price'].toString()) ?? 0.0;

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
  // --- ฟังก์ชันสั่งพิมพ์ซ้ำ ---
Future<void> _rePrint(BuildContext context, WidgetRef ref, dynamic logData) async {
    try {
      print("rePrint($logData)");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กำลังเตรียมข้อมูลพิมพ์...")));

      final itemsRaw = logData['items'] as List<dynamic>? ?? [];
      
      final service = ref.read(sellHistoryServiceProvider);
      final itemsToPrint = service.convertLogToCartItems(itemsRaw);
      final custAddr = logData['customer']?['address'] ?? '-';
      final custPhone = logData['customer']?['tel'] ?? '-';
      final saleName = logData['truck_name'] ?? '-';

      if (itemsToPrint.isEmpty) throw Exception("ไม่พบรายการสินค้าในบิลนี้");
      
      // [เพิ่ม] ดึงค่า is_credit จาก Log มาเช็ค
      // API น่าจะส่งมาเป็น string ("week", "month") หรือ null/false
      final isCreditVal = logData['is_credit']; 
      bool isCreditBool = false;

      if (isCreditVal != null && isCreditVal != false && isCreditVal != "cash") {
         isCreditBool = true;
      }
      
      await PrintService().printReceipt(
        context,
        itemsToPrint,
        customerName: logData['customer']?['name'],
        customerAddress: custAddr,
        customerPhone: custPhone,
        salespersonName: saleName,
        isCredit: isCreditBool, // [แก้ไข] ส่งค่า isCredit ไปด้วย
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