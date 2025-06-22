import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/cart_provider.dart';
import '../models/product_model.dart';

class CartScreen extends ConsumerWidget {
  final Customer customer;
  const CartScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carts = ref.watch(cartWithQuantityProvider);
    final totalAmount = ref.watch(cartTotalAmountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          IconButton(onPressed: () {
            ref.read(cartProvider.notifier).clear();
          }, icon: Icon(Icons.clear_all))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: carts.length,
              itemBuilder: (context, index) {
                final product = carts.keys.elementAt(index);
                final quantity = carts.values.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(product.description),
                    subtitle: Text(
                      'Price: ${product.sellPrice} ${product.unit}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            ref.read(cartProvider.notifier).removeItem(product);
                          },
                        ),
                        Text('$quantity'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            ref.read(cartProvider.notifier).addItem(product);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewPadding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: \$${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(customer: customer,)));
              },
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
} 