import 'dart:async';

import 'package:brightmotor_store/components/product_tile.dart';
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
    final itemCount = ref.watch(cartItemCountProvider);
    final selectedCategory = useState<String?>("ทั้งหมด");
    final products = ref.watch(productByCategoriesProvider(
        ProductCategoryParams(
            truckId: truckId, category: selectedCategory.value)));
    final categories = ref.watch(productCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products by Category'),
        actions: [
          IconButton(onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductSearchScreen(cartVisible: true, customer: customer,),
              ),
            );
          }, icon: Icon(Icons.search))
        ],
      ),
      body: Column(
        children: [
          // Category buttons
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

          // Products list
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductTile(
                  product: product,
                  onAction: (product) {
                    ref.read(cartProvider.notifier).addItem(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
    );
  }
}
