import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/screens/customer_screen.dart';
import 'package:brightmotor_store/screens/login_screen.dart';
import 'package:brightmotor_store/screens/product/product_screen.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truck = ref.watch(currentTruckProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${truck?.fullName ?? '-'}'),
        centerTitle: false,
        actions: [
          IconButton(
              onPressed: () {
                showAdaptiveDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                SessionPreferences().logout();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ));
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text("Select Menu",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                  ),
                  GestureDetector(
                    onTap: () async {
                      //choose customer
                      final customer = await launchCustomerChooser(context);
                      if (customer == null) return;

                      // launch product screen by sending customer into it.
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductScreen(customer: customer)));


                    },
                    child: Card(
                      child: ListTile(
                        title: Text("Open Order"),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
