import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/screens/customer_screen.dart';
import 'package:brightmotor_store/screens/login_screen.dart';
import 'package:brightmotor_store/screens/printer/printer_page.dart';
import 'package:brightmotor_store/screens/product/product_screen.dart';
import 'package:brightmotor_store/screens/product/product_search_screen.dart';
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
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (truck?.truckId != null) {
                            final customer = await launchCustomerChooser(context);
                            if (customer == null) return;
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductScreen(customer: customer)));
                          } else {
                            showAdaptiveDialog(context: context, builder: (context) => AlertDialog(
                              content: Text("Cannot create order without truck info"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Close"),
                                ),
                              ],
                            ));
                          }
                        },
                        child: Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_cart, size: 48),
                                SizedBox(height: 8),
                                Text("Open Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductSearchScreen()));
                        },
                        child: Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.list_alt, size: 48),
                                SizedBox(height: 8),
                                Text("Products", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PrinterPage()));
                        },
                        child: Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.print, size: 48),
                                SizedBox(height: 8),
                                Text("Printer Setting", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Add more menu tiles here for 2x2 grid if needed
                    ],
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
