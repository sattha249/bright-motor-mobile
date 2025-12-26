import 'package:brightmotor_store/components/product_tile.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/providers/cart_provider.dart'; // ตรวจสอบ path นี้ให้ถูกต้อง
import 'package:brightmotor_store/providers/product_search_provider.dart';
import 'package:brightmotor_store/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProductSearchScreen extends ConsumerWidget {
  final Customer? customer;
  final bool cartVisible;

  const ProductSearchScreen({
    super.key,
    this.cartVisible = false,
    this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ดึงข้อมูลสินค้า (State)
    final result = ref.watch(productSearchProvider);
    
    // 2. ดึง Notifier เพื่อเรียกฟังก์ชันและเช็คสถานะ (isLoading, hasMore)
    final notifier = ref.read(productSearchProvider.notifier);
    
    final itemCount = ref.watch(cartItemCountProvider);
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Search Product',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            ref.read(productSearchProvider.notifier).search(value);
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.builder(
              // เพิ่ม +1 เสมอ เพื่อเป็นพื้นที่สำหรับ Loading Indicator หรือข้อความ "หมด" ด้านล่าง
              itemCount: result.length + 1,
              itemBuilder: (context, index) {
                // --- ส่วนแสดงรายการสินค้าปกติ ---
                if (index < result.length) {
                  final product = result[index];
                  return ProductTile(
                    product: product,
                    actionVisible: cartVisible,
                    onAction: (product) {
                      ref.read(cartProvider.notifier).addItem(product);
                    },
                  );
                }

                // --- ส่วนจัดการ Pagination (รายการสุดท้าย) ---
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        // 1. ถ้าโหลดครบทุกหน้าแล้ว (ไม่มีข้อมูลเหลือ)
                        if (!notifier.hasMore) {
                          // ถ้าไม่มีสินค้าเลยสักชิ้น ให้บอกว่า "ไม่พบสินค้า"
                          if (result.isEmpty) {
                            return const Text(
                              "ไม่พบสินค้า",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            );
                          }
                          // ถ้ามีสินค้าแล้ว แต่โหลดจนครบ
                          return const Text(
                            "สิ้นสุดรายการสินค้า",
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        // 2. ถ้ายังมีข้อมูลเหลือ และไม่ได้กำลังโหลดอยู่ -> สั่งโหลดเพิ่ม
                        if (!notifier.isLoading) {
                          Future.microtask(() => notifier.fetchNextPage());
                        }

                        // 3. แสดง Loading Indicator
                        return const CircularProgressIndicator.adaptive();
                      },
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: Visibility(
        visible: itemCount > 0 && customer != null,
        child: Stack(
          children: [
            FloatingActionButton(
              onPressed: () {
                final data = customer;
                if (data == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      customer: data,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.shopping_cart),
            ),
            if (itemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}