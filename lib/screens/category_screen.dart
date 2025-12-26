import 'dart:async';

import 'package:brightmotor_store/components/product_tile.dart';
import 'package:brightmotor_store/models/cart_model.dart'; // Import CartItem
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/providers/product_provider.dart';
import 'package:brightmotor_store/screens/product/product_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class CategoryScreen extends HookConsumerWidget {
  final Customer? customer;

  const CategoryScreen({super.key, this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truckId = ref.watch(currentTruckIdProvider);
    
    // ดึงจำนวนสินค้าทั้งหมดในตะกร้า (สำหรับ Badge)
    final itemCount = ref.watch(cartItemCountProvider);
    
    // ดึงรายการสินค้าในตะกร้า (เพื่อมาเช็คสต็อกรายตัว)
    final cartItems = ref.watch(cartProvider);

    final selectedCategory = useState<String?>("ทั้งหมด");
    
    // กระตุ้นให้โหลดข้อมูลสินค้า
    ref.watch(productsProvider);
    
    final products = ref.watch(productByCategoriesProvider(
        ProductCategoryParams(
            truckId: truckId, category: selectedCategory.value)));
    final categories = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้า'),
        actions: [
          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductSearchScreen(cartVisible: true, customer: customer,),
              ),
            );
          }, icon: const Icon(Icons.search))
        ],
      ),
      body: Column(
        children: [
          // --- Category Buttons ---
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories.keys.elementAt(index);
                final count = categories[category]!;
                final isSelected = category == selectedCategory.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    onSelected: (_) => selectedCategory.value = category,
                    selected: isSelected,
                    label: Text('$category ($count)'),
                  ),
                );
              },
            ),
          ),

          // --- Products List ---
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                // [แก้ไข Logic ให้รองรับ CartItem]
                // 1. หาว่าสินค้านี้มีอยู่ในตะกร้าหรือยัง
                final existingCartItem = cartItems.firstWhere(
                  (item) => item.product.id == product.id,
                  // ถ้าไม่เจอ ให้สร้าง Dummy Object ที่มี quantity 0
                  orElse: () => CartItem(product: product, quantity: 0),
                );

                // 2. ดึงจำนวนที่อยู่ในตะกร้า
                final countInCart = existingCartItem.quantity;

                // 3. คำนวณจำนวนที่เหลือ (Stock - Cart)
                final remainingQty = product.quantity - countInCart;

                // 4. สร้าง Product ตัวใหม่เพื่อแสดงผล (หลอก UI ว่าเหลือเท่านี้)
                final displayProduct = product.copyWith(quantity: remainingQty);

                return ProductTile(
                  product: displayProduct, // โชว์ตัวเลขที่ลดลงแล้ว
                  onAction: (_) {
                    // ใช้ remainingQty ที่คำนวณไว้มาเช็ค
                    if (remainingQty > 0) {
                      // เพิ่มสินค้า (CartNotifier จะจัดการรวมยอดให้เอง)
                      ref.read(cartProvider.notifier).addItem(product);
                    } else {
                      // แจ้งเตือนเมื่อสินค้าหมด
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'สินค้าหมด! (สต็อก: ${product.quantity} ${product.unit})',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(milliseconds: 1000),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // --- Floating Action Button (Cart) ---
      floatingActionButton: Stack(
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
    );
  }
}