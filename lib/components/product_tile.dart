
import 'package:brightmotor_store/models/product_model.dart';
import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final bool actionVisible;
  final Function(Product)? onAction;
  const ProductTile({super.key, required this.product, this.actionVisible = true, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: ListTile(
        title: Text(product.description),
        subtitle: Text(
          'ราคา: ${product.sellPrice} / ${product.unit}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.brand.isNotEmpty ? product.brand : 'No brand'),
            Visibility(
              visible: actionVisible,
              child: IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {
                  onAction?.call(product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
