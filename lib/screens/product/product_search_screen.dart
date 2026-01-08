import 'dart:async';
import 'package:brightmotor_store/components/product_tile.dart';
import 'package:brightmotor_store/models/cart_model.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/product_search_provider.dart';
import 'package:brightmotor_store/screens/cart_screen.dart';
import 'package:flutter/material.dart';
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
                      print("result = ${result.first.toJson()}");
                      final product = result[index];

                      // --- [LOGIC from CategoryScreen] ---
                      
                      // 1. Find if product is already in cart
                      final existingCartItem = cartItems.firstWhere(
                        (item) => item.product.id == product.id,
                        orElse: () => CartItem(product: product, quantity: 0),
                      );

                      // 2. Get quantity in cart
                      final countInCart = existingCartItem.quantity;

                      // 3. Calculate remaining stock
                      final remainingQty = product.quantity - countInCart;

                      // 4. Create display product with updated quantity
                      final displayProduct = product.copyWith(quantity: remainingQty);

                      return ProductTile(
                        product: displayProduct, // Pass the calculated product
                        // actionVisible: cartVisible, // Optional: control visibility if needed
                        onAction: (_) {
                          // Check remaining stock before adding
                          if (remainingQty > 0) {
                            ref.read(cartProvider.notifier).addItem(product);
                            
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เพิ่ม ${product.description} ลงตะกร้า'),
                                duration: const Duration(milliseconds: 500),
                              ),
                            );
                          } else {
                            // Out of stock feedback
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'สินค้าหมด! (สต็อก: ${product.quantity} ${product.unit})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 1000),
                              ),
                            );
                          }
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