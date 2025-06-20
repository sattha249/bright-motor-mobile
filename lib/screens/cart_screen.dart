import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //TODO add remove all items
    //TODO add remove item (swipe left and remove it)
    //TODO adjust UI for this
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // if (cart.itemCount == 0) {
        //   return const Center(
        //     child: Text('Your cart is empty'),
        //   );
        // }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cart'),
            actions: [
              IconButton(onPressed: () {
                //TODO clear all items
                Provider.of<CartProvider>(context, listen: false).clear();
              }, icon: Icon(Icons.clear_all))
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final product = cart.items.keys.elementAt(index);
                    final quantity = cart.items[product]!;

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
                                cart.removeItem(product);
                              },
                            ),
                            Text('$quantity'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                cart.addItem(product);
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
                  'Total: \$${cart.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement checkout functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checkout functionality coming soon!'),
                      ),
                    );
                  },
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 