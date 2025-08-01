import 'package:brightmotor_store/models/customer.dart';
import 'package:brightmotor_store/providers/cart_provider.dart';
import 'package:brightmotor_store/providers/product_provider.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/screens/complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum PaymentMethod {
  cash,
  weeklyCredit,
  monthlyCredit;

  String get title {
    switch (this) {
      case PaymentMethod.cash:
        return "Cash";
      case PaymentMethod.weeklyCredit:
        return "Weekly Credit";
      case PaymentMethod.monthlyCredit:
        return "Monthly Credit";
    }
  }
}

String priceToString(double price) {
  return price.toStringAsFixed(2);
}

class CheckoutScreen extends HookConsumerWidget {
  final Customer customer;

  const CheckoutScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truckId = ref.watch(currentTruckIdProvider);
    final carts = ref.watch(cartWithQuantityProvider);
    final totalPrice = ref.watch(cartTotalPriceProvider);
    final currentPaymentMethod = useState(PaymentMethod.cash);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "รายการ",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final product = carts.keys.elementAt(index);
                              final quantity = carts.values.elementAt(index);
                              return ListTile(
                                title: Text("${product.description} x$quantity",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                trailing: Text(
                                  priceToString(
                                      double.parse(product.sellPrice) *
                                          quantity),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                minTileHeight: 36,
                              );
                            },
                            itemCount: carts.length,
                          ),
                          ListTile(
                            title: Text(
                              "ยอดรวม",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(totalPrice,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "เลือกช่องทางการชำระเงิน",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        PaymentMethodListTile(
                          paymentMethod: PaymentMethod.cash,
                          selected:
                              currentPaymentMethod.value == PaymentMethod.cash,
                          onTap: (value) => currentPaymentMethod.value = value,
                        ),
                        PaymentMethodListTile(
                          contentPadding: EdgeInsets.only(top: 16),
                          paymentMethod: PaymentMethod.weeklyCredit,
                          selected: currentPaymentMethod.value ==
                              PaymentMethod.weeklyCredit,
                          onTap: (value) => currentPaymentMethod.value = value,
                        ),
                        PaymentMethodListTile(
                          contentPadding: EdgeInsets.only(top: 16),
                          paymentMethod: PaymentMethod.monthlyCredit,
                          selected: currentPaymentMethod.value ==
                              PaymentMethod.monthlyCredit,
                          onTap: (value) => currentPaymentMethod.value = value,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16)
            .copyWith(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: ElevatedButton(
            onPressed: () async {

          if (truckId == null) return;
          final customerId = customer.id;
          final isCredit = currentPaymentMethod.value != PaymentMethod.cash;
          final items = carts;

          try {
            await ref.read(cartProvider.notifier).submit(truckId, customerId, isCredit, items);
            await launchCheckoutCompleteScreen(context);
            Navigator.of(context).popUntil((route) => route.isFirst);
          } catch (e, stacktrace) {
            print(stacktrace);
          }

        }, child: Text("ชำระเงิน")),
      ),
    );
  }
}

class PaymentMethodListTile extends StatelessWidget {
  final bool selected;
  final PaymentMethod paymentMethod;
  final Function(PaymentMethod)? onTap;
  final EdgeInsets? contentPadding;

  const PaymentMethodListTile({
    super.key,
    required this.paymentMethod,
    required this.selected,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: contentPadding ?? EdgeInsets.zero,
      child: ListTile(
        onTap: () {
          onTap?.call(paymentMethod);
        },
        selected: selected,
        title: Text(
          paymentMethod.title,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }
}
