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

  Widget _buildPreOrderBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Text(
        "Preorder: $count",
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAvailableBadge(int count) {
    final isNegative = count < 0;
    final baseColor = isNegative ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: baseColor.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.shade300),
      ),
      child: Text(
        "ขายได้: $count",
        style: TextStyle(
          color: baseColor.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
              : RefreshIndicator(
                  onRefresh: () => notifier.loadInitial(),
                  child: ListView.separated(
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
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                        ),
                        title: Text(
                          item.product.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              "รหัส: ${item.product.productCode} | ราคา: ฿${item.product.sellPrice}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildPreOrderBadge(item.preOrderQuantity),
                                _buildAvailableBadge(item.availableQuantity),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            "${item.quantity} ${item.product.unit}",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
