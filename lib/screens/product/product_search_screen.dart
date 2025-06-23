import 'package:brightmotor_store/components/product_tile.dart';
import 'package:brightmotor_store/providers/product_search_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProductSearchScreen extends ConsumerWidget {
  const ProductSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(productSearchProvider);
    final controller = TextEditingController();
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
                  actionVisible: false,
                );
              },
              itemCount: result.length,
            ),
          )
        ],
      ),
    );
  }
}
