import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = MockCustomerService();
  final List<Customer> _customers = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!_hasMorePages) return;

    try {
      final result = await _customerService.getCustomers(page: _currentPage);
      setState(() {
        _customers.addAll(result['customers'] as List<Customer>);
        _hasMorePages = _currentPage < result['meta']['last_page'];
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: _isLoading && _customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _customers.isEmpty
              ? Center(child: Text('Error: $_error'))
              : ListView.builder(
                  itemCount: _customers.length + (_hasMorePages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _customers.length) {
                      _loadCustomers();
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final customer = _customers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(customer.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer No: ${customer.customerNo}'),
                            Text('Tel: ${customer.tel}'),
                            if (customer.address.isNotEmpty)
                              Text('Address: ${customer.address}'),
                            if (customer.district.isNotEmpty)
                              Text('District: ${customer.district}'),
                            if (customer.province.isNotEmpty)
                              Text('Province: ${customer.province}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
} 