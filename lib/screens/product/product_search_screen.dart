import 'dart:async';
import 'package:brightmotor_store/components/product_tile.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/product_search_provider.dart';
import 'package:brightmotor_store/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [เพิ่ม] สำหรับ FilteringTextInputFormatter
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProductSearchScreen extends HookConsumerWidget {
  final Customer? customer;
  final bool cartVisible;

  const ProductSearchScreen({
    super.key,
    this.cartVisible = false,
    this.customer,
  });

  void _showQuantityDialog(
      BuildContext context, WidgetRef ref, Product product, int maxQty,
      {int countInCart = 0}) {
    showDialog(
      context: context,
      builder: (context) {
        int currentQty = maxQty > 0 ? 1 : 0;
        final TextEditingController controller =
            TextEditingController(text: currentQty.toString());

        return StatefulBuilder(
          builder: (context, setState) {
            void updateQty(int newQty) {
              if (newQty < (maxQty > 0 ? 1 : 0)) {
                newQty = maxQty > 0 ? 1 : 0;
              }
              if (newQty > maxQty) {
                newQty = maxQty;
              }

              setState(() {
                currentQty = newQty;
                controller.text = newQty.toString();
                controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length));
              });
            }

            final isNegativeAvailable = product.availableQuantity < 0;
            final availableColor = isNegativeAvailable ? Colors.red : Colors.green;

            return AlertDialog(
              title: Text(
                product.description,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "สต็อกในรถ: ${product.quantity} ${product.unit}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Badge สีน้ำเงิน: Preorder
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Text(
                          "Preorder: ${product.preOrderQuantity}",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Badge สีเขียว/แดง: ขายได้
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isNegativeAvailable ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isNegativeAvailable ? Colors.red.shade300 : Colors.green.shade300,
                          ),
                        ),
                        child: Text(
                          "ขายได้: ${product.availableQuantity}",
                          style: TextStyle(
                            color: availableColor.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (countInCart > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "อยู่ในตะกร้าแล้ว: $countInCart ${product.unit}",
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  Text(
                    maxQty > 0
                        ? "สามารถเพิ่มได้: $maxQty ${product.unit}"
                        : "ไม่สามารถเพิ่มได้ (สินค้าที่ขายได้ไม่เพียงพอ)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: maxQty > 0 ? Colors.grey.shade700 : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: (maxQty > 0 && currentQty > 1)
                            ? () => updateQty(currentQty - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        iconSize: 32,
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          enabled: maxQty > 0,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            int? val = int.tryParse(value);
                            if (val != null) {
                              if (val > maxQty) {
                                updateQty(maxQty);
                              } else {
                                setState(() => currentQty = val);
                              }
                            } else {
                              setState(() => currentQty = 0);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: currentQty < maxQty
                            ? () => updateQty(currentQty + 1)
                            : null,
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
                  onPressed: (currentQty > 0 && currentQty <= maxQty)
                      ? () {
                          final notifier = ref.read(cartProvider.notifier);
                          notifier.addItem(product, quantity: currentQty);

                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เพิ่ม $currentQty ${product.unit} เรียบร้อย'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      : null,
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch search results (State)
    final result = ref.watch(productSearchProvider);
    
    // 2. Fetch Notifier for actions and state checks
    final notifier = ref.read(productSearchProvider.notifier);
    
    // 3. Cart data for stock calculation
    final cartItems = ref.watch(cartProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    
    final controller = useTextEditingController();
    final hasSearched = useState(false);
    final debounceTimer = useRef<Timer?>(null);

    void onSearchChanged(String query) {
      if (debounceTimer.value?.isActive ?? false) {
        debounceTimer.value?.cancel();
      }
      debounceTimer.value = Timer(const Duration(milliseconds: 500), () {
        if (query.isNotEmpty) {
          hasSearched.value = true;
          notifier.search(query);
        } else {
          hasSearched.value = false;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ค้นหาสินค้า...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
        ),
      ),
      body: Builder(
        builder: (context) {
          // Case 1: Initial State (No search yet)
          if (!hasSearched.value && result.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "พิมพ์ชื่อสินค้าเพื่อค้นหา",
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          // Case 2: Loading (First load)
          if (notifier.isLoading && result.isEmpty) {
             return const Center(child: CircularProgressIndicator.adaptive());
          }

          // Case 3: No Results
          if (result.isEmpty && !notifier.isLoading && hasSearched.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "ไม่พบสินค้า",
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          // Case 4: Results List
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.builder(
                  itemCount: result.length + 1,
                  itemBuilder: (context, index) {
                    // --- Product Item Logic ---
                    if (index < result.length) {
                      final product = result[index];

                      final existingCartItem = cartItems.firstWhere(
                        (item) => item.product.id == product.id,
                        orElse: () => CartItem(product: product, quantity: 0),
                      );
                      final countInCart = existingCartItem.quantity;
                      final maxAddable = product.availableQuantity - countInCart;
                      final remainingQty = maxAddable > 0 ? maxAddable : 0;
                      final displayProduct = product.copyWith(quantity: remainingQty);

                      return ProductTile(
                        product: displayProduct, 
                        onAction: (_) {
                          _showQuantityDialog(context, ref, product, remainingQty, countInCart: countInCart);
                        },
                      );
                    }

                    // --- Pagination Loader ---
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Builder(
                          builder: (context) {
                            if (!notifier.hasMore) {
                              return const Text(
                                "สิ้นสุดรายการสินค้า",
                                style: TextStyle(color: Colors.grey),
                              );
                            }
                            if (!notifier.isLoading) {
                              Future.microtask(() => notifier.fetchNextPage());
                            }
                            return const CircularProgressIndicator.adaptive();
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
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