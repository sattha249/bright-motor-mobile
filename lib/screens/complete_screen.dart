import 'package:brightmotor_store/printer/print_service.dart';
import 'package:brightmotor_store/screens/printer/printer_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/cart_provider.dart';

Future<dynamic> launchCheckoutCompleteScreen(BuildContext context) {
  return Navigator.of(context).push(MaterialPageRoute(builder: (context) => CompleteScreen(), fullscreenDialog: true));
}

class CompleteScreen extends ConsumerWidget {
  const CompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartWithQuantityProvider);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Checkout Completed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Close'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    PrintService().printReceipt(cart);
                  },
                  child: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
