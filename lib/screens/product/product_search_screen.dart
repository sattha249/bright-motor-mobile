import 'package:brightmotor_store/components/product_tile.dart';
import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/providers/product_search_provider.dart';
import 'package:brightmotor_store/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/cart_provider.dart';

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
    final result = ref.watch(productSearchProvider);
    final controller = TextEditingController();
    final itemCount = ref.watch(cartItemCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search Product',
          ),
          onSubmitted: (value) {
            ref.read(productSearchProvider.notifier).search(value);
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList.builder(
              itemBuilder: (context, index) {
                final product = result[index];
                return ProductTile(
                  product: product,
                  actionVisible: cartVisible,
                  onAction: (product) {
                    ref.read(cartProvider.notifier).addItem(product);
                  },
                );
              },
              itemCount: result.length,
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
                  padding: const EdgeInsets.all(2),
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
