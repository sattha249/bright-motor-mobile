import 'dart:async';
import 'package:brightmotor_store/providers/truck_stock_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TruckStockScreen extends ConsumerStatefulWidget {
  const TruckStockScreen({super.key});

  @override
  ConsumerState<TruckStockScreen> createState() => _TruckStockScreenState();
}

class _TruckStockScreenState extends ConsumerState<TruckStockScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Debounce 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length >= 2 || query.isEmpty) {
        ref.read(truckStockProvider.notifier).search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stocks = ref.watch(truckStockProvider);
    final notifier = ref.read(truckStockProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้าในรถ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ค้นหารหัส, ชื่อสินค้า...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: stocks.isEmpty && notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : stocks.isEmpty
              ? const Center(child: Text("ไม่พบสินค้า"))
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: stocks.length + (notifier.hasMore ? 1 : 0),
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // --- ส่วน Loading ท้ายรายการ ---
                    if (index == stocks.length) {
                      Future.microtask(() => notifier.fetchNextPage());
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    // --- รายการสินค้า ---
                    final item = stocks[index];
                    return ListTile(
                      // [ปรับปรุง 1] เปลี่ยนไอคอนด้านหน้าเป็นรูปกล่อง (เพราะเอาตัวเลขไปไว้ขวาแล้ว)
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                      ),
                      title: Text(item.product.description),
                      subtitle: Text(
                        "รหัส: ${item.product.productCode} | ราคา: ฿${item.product.sellPrice}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      // [ปรับปรุง 2] โชว์ Quantity คู่กับ Unit ในกรอบสีฟ้า
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          "${item.quantity} ${item.product.unit}", // <--- แสดงผลตรงนี้ครับ
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}