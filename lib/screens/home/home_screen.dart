import 'package:brightmotor_store/components/offline_dialog.dart';
import 'package:brightmotor_store/providers/health_provider.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/screens/customer_screen.dart';
import 'package:brightmotor_store/screens/login_screen.dart';
import 'package:brightmotor_store/screens/printer/printer_page.dart';
import 'package:brightmotor_store/screens/product/product_screen.dart';
import 'package:brightmotor_store/screens/truck_stock_screen.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:brightmotor_store/screens/pre_order_screen.dart';
import 'package:brightmotor_store/screens/sync_data_screen.dart';
import 'package:brightmotor_store/screens/sell_history_screen.dart';
import 'package:brightmotor_store/screens/product/system_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truck = ref.watch(currentTruckProvider);
    final health = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('สวัสดี ${truck?.fullName ?? '-'}'),
        centerTitle: false,
        actions: [
          // Online / Offline Status Chip
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('กำลังตรวจสอบสถานะการเชื่อมต่อ...'),
                  duration: Duration(seconds: 1),
                ),
              );
              final isOnline =
                  await ref.read(healthProvider.notifier).checkHealth();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isOnline
                          ? '🟢 เชื่อมต่อกับเซิร์ฟเวอร์เรียบร้อย (Online)'
                          : '🔴 ไม่พบการเชื่อมต่อกับเซิร์ฟเวอร์ (Offline)',
                    ),
                    backgroundColor: isOnline ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: health.isOnline
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: health.isOnline
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    health.isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: health.isOnline ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    health.isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: health.isOnline
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              showAdaptiveDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        SessionPreferences().logout();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner แจ้งเตือนสถานะ Offline
                  if (!health.isOnline) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'ขณะนี้อยู่ในโหมดออฟไลน์ (Offline Mode)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'อนุญาตเฉพาะการขายหน้ารถ และคำสั่งซื้อล่วงหน้า ข้อมูลจะถูกบันทึกไว้ในเครื่อง',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "เมนูหลัก",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      // 1. เปิดคำสั่งซื้อ (ขายหน้ารถ)
                      GestureDetector(
                        onTap: () async {
                          if (truck?.truckId == null) {
                            showAdaptiveDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: const Text(
                                    "Cannot create order without truck info"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("Close"),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          void openOrderScreen() async {
                            final customer =
                                await launchCustomerChooser(context);
                            if (customer == null || !context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductScreen(customer: customer),
                              ),
                            );
                          }

                          if (!health.isOnline) {
                            await OfflineNoticeDialog.show(
                              context,
                              title: 'ขายหน้ารถ (ออฟไลน์)',
                              message:
                                  'คุณกำลังเปิดคำสั่งซื้อขายหน้ารถในโหมดออฟไลน์ รายการขายจะถูกบันทึกไว้ในเครื่อง และรอส่งข้อมูลเมื่อกลับมาออนไลน์',
                              onAcknowledge: openOrderScreen,
                            );
                          } else {
                            openOrderScreen();
                          }
                        },
                        child: const Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_cart,
                                    size: 48, color: Colors.blue),
                                SizedBox(height: 8),
                                Text("เปิดคำสั่งซื้อ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. สินค้าในรถ
                      GestureDetector(
                        onTap: () async {
                          void openTruckStock() {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TruckStockScreen(),
                              ),
                            );
                          }

                          if (!health.isOnline) {
                            await OfflineNoticeDialog.show(
                              context,
                              title: 'สินค้าในรถ (ออฟไลน์)',
                              message:
                                  'ระบบจะแสดงรายการสินค้าในรถจากข้อมูลล่าสุดที่บันทึกไว้ในเครื่อง',
                              onAcknowledge: openTruckStock,
                            );
                          } else {
                            openTruckStock();
                          }
                        },
                        child: const Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.list_alt,
                                    size: 48, color: Colors.green),
                                SizedBox(height: 8),
                                Text("สินค้าในรถ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 3. คำสั่งซื้อล่วงหน้า (Pre-order)
                      GestureDetector(
                        onTap: () async {
                          void openPreOrder() {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PreOrderScreen(),
                              ),
                            );
                          }

                          if (!health.isOnline) {
                            await OfflineNoticeDialog.show(
                              context,
                              title: 'คำสั่งซื้อล่วงหน้า (ออฟไลน์)',
                              message:
                                  'คุณกำลังสร้างคำสั่งซื้อล่วงหน้าในโหมดออฟไลน์ ระบบจะบันทึกข้อมูลไว้ในเครื่องเพื่อรอซิงค์ข้อมูลภายหลัง',
                              onAcknowledge: openPreOrder,
                            );
                          } else {
                            openPreOrder();
                          }
                        },
                        child: const Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_filled,
                                    size: 48, color: Colors.orange),
                                SizedBox(height: 8),
                                Text("คำสั่งซื้อล่วงหน้า",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 4. อัพเดทข้อมูล (Sync) - ต้องใช้อินเทอร์เน็ต
                      GestureDetector(
                        onTap: () async {
                          if (!health.isOnline) {
                            await OfflineNoticeDialog.show(
                              context,
                              title: 'อัปเดตข้อมูลไม่ได้',
                              message:
                                  'ไม่สามารถอัปเดตข้อมูลกับเซิร์ฟเวอร์ได้ในขณะนี้ เนื่องจากแอปอยู่ในโหมดออฟไลน์',
                              isBlocked: true,
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SyncDataScreen(),
                              ),
                            );
                          }
                        },
                        child: const Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync, size: 48, color: Colors.blue),
                                SizedBox(height: 8),
                                Text("อัพเดทข้อมูล",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 5. ตั้งค่าเครื่องพิมพ์ (Local)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PrinterPage(),
                            ),
                          );
                        },
                        child: const Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.print, size: 48),
                                SizedBox(height: 8),
                                Text("ตั้งค่าเครื่องพิมพ์",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 6. ประวัติการขาย
                      GestureDetector(
                        onTap: () async {
                          if (truck?.truckId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("ไม่พบข้อมูล Truck ID")),
                            );
                            return;
                          }

                          void openSellHistory() {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SellHistoryScreen(),
                              ),
                            );
                          }

                          if (!health.isOnline) {
                            await OfflineNoticeDialog.show(
                              context,
                              title: 'ประวัติการขาย (ออฟไลน์)',
                              message:
                                  'ระบบจะแสดงประวัติการขายล่าสุดที่มีการเก็บบันทึกไว้ในเครื่อง',
                              onAcknowledge: openSellHistory,
                            );
                          } else {
                            openSellHistory();
                          }
                        },
                        child: const Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history,
                                    size: 48, color: Colors.purple),
                                SizedBox(height: 8),
                                Text("ประวัติการขาย",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 7. สินค้าในระบบ - ต้องใช้อินเทอร์เน็ต
                      GestureDetector(
                        onTap: () async {
                          if (!health.isOnline) {
                            await OfflineNoticeDialog.show(
                              context,
                              title: 'ไม่พบการเชื่อมต่อ',
                              message:
                                  'ไม่สามารถดูรายการสินค้าทั้งหมดในระบบได้ในขณะนี้ เนื่องจากสินค้าในระบบต้องดึงจากเซิร์ฟเวอร์แบบออนไลน์เท่านั้น',
                              isBlocked: true,
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SystemProductScreen(),
                              ),
                            );
                          }
                        },
                        child: const Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory,
                                    size: 48, color: Colors.teal),
                                SizedBox(height: 8),
                                Text("สินค้าในระบบ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
