import 'dart:async';
import 'package:brightmotor_store/components/product_tile.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/models/product_model.dart'; // อย่าลืม import Product model
import 'package:brightmotor_store/providers/product_provider.dart';
import 'package:brightmotor_store/screens/product/product_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับ FilteringTextInputFormatter
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
    final itemCount = ref.watch(cartItemCountProvider);
    final cartItems = ref.watch(cartProvider);
    final selectedCategory = useState<String?>("ทั้งหมด");

    ref.watch(productsProvider);

    final products = ref.watch(productByCategoriesProvider(
        ProductCategoryParams(
            truckId: truckId, category: selectedCategory.value)));
    final categories = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้า'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductSearchScreen(
                      cartVisible: true,
                      customer: customer,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.search))
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

                // Logic เดิม: หาจำนวนที่เหลือ (Stock - Cart)
                final existingCartItem = cartItems.firstWhere(
                  (item) => item.product.id == product.id,
                  orElse: () => CartItem(product: product, quantity: 0),
                );
                final countInCart = existingCartItem.quantity;
                final remainingQty = product.quantity - countInCart;
                
                // สินค้าที่จะแสดงผล (ปรับ quantity ตามที่เหลือจริง)
                final displayProduct = product.copyWith(quantity: remainingQty);

                return ProductTile(
                  product: displayProduct,
                  onAction: (_) {
                    if (remainingQty > 0) {
                      // [แก้ไข] เรียก Dialog แทนการ add ทันที
                      _showQuantityDialog(context, ref, product, remainingQty);
                    } else {
                      // แจ้งเตือนสินค้าหมด
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

  // [เพิ่ม] ฟังก์ชันแสดง Dialog ใส่จำนวน
  void _showQuantityDialog(
      BuildContext context, WidgetRef ref, Product product, int maxQty) {
    
    // ใช้ StatefulBuilder เพื่อให้ Dialog สามารถ update UI (ตัวเลข) ภายในตัวเองได้
    showDialog(
      context: context,
      builder: (context) {
        // ตัวแปรเก็บจำนวนที่เลือก เริ่มต้นที่ 1
        int currentQty = 1;
        // Controller สำหรับ TextField
        final TextEditingController controller = TextEditingController(text: '1');

        return StatefulBuilder(
          builder: (context, setState) {
            
            // ฟังก์ชันอัพเดทค่า
            void updateQty(int newQty) {
              if (newQty < 0) newQty = 0;
              if (newQty > maxQty) newQty = maxQty;
              
              setState(() {
                currentQty = newQty;
                controller.text = newQty.toString();
                // ย้าย cursor ไปท้ายสุดเวลากดปุ่ม
                controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length));
              });
            }

            return AlertDialog(
              title: Text(product.description), // แสดงชื่อสินค้า
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("คงเหลือในสต็อกที่เพิ่มได้: $maxQty ${product.unit}", 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ปุ่มลบ (-)
                      IconButton(
                        onPressed: currentQty > 0 
                            ? () => updateQty(currentQty - 1) 
                            : null, // disable ถ้าเป็น 0
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        iconSize: 32,
                      ),
                      
                      // ช่องกรอกตัวเลข
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            // Logic เมื่อพิมพ์เอง
                            int? val = int.tryParse(value);
                            if (val != null) {
                              // ถ้าพิมพ์เกิน max ให้ปัดลงมาเท่า max ทันที (หรือจะรอตอนกดตกลงก็ได้)
                              if (val > maxQty) {
                                updateQty(maxQty);
                              } else {
                                setState(() => currentQty = val);
                              }
                            } else {
                               // กรณีลบจนว่าง ให้ถือเป็น 0
                               setState(() => currentQty = 0);
                            }
                          },
                        ),
                      ),
                      
                      // ปุ่มบวก (+)
                      IconButton(
                        onPressed: currentQty < maxQty 
                            ? () => updateQty(currentQty + 1) 
                            : null, // disable ถ้าเต็ม max
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.green,
                        iconSize: 32,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: currentQty > 0 // กดได้ต่อเมื่อจำนวน > 0
                      ? () {
                          // [สำคัญ] เพิ่มสินค้าเข้าตะกร้าตามจำนวนที่ระบุ
                          final notifier = ref.read(cartProvider.notifier);
                          
                          // เนื่องจาก addItem เดิมอาจจะรับทีละ 1 
                          // เราสามารถ loop เรียก หรือ ถ้าใน cartNotifier มีฟังก์ชันรับ quantity ก็ใช้ตัวนั้น
                          // สมมติว่า addItem รับได้แค่ทีละ 1 (Safe approach)
                          for (int i = 0; i < currentQty; i++) {
                             notifier.addItem(product);
                          }
                          
                          // หรือถ้า CartNotifier ของคุณมี method: addItem(product, quantity: n) 
                          // ให้ใช้แบบนี้จะดีกว่า (ประสิทธิภาพดีกว่า):
                          // notifier.addItem(product, quantity: currentQty);

                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เพิ่ม $currentQty รายการเรียบร้อย')),
                          );
                        }
                      : null, // disable ปุ่มตกลงถ้าจำนวนเป็น 0
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}