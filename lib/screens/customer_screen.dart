import 'package:flutter/material.dart';
import 'dart:async';
import '../models/customer.dart';
import '../services/customer_service.dart';

Future<Customer?> launchCustomerChooser(BuildContext context) {
  return Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomerScreen(), fullscreenDialog: true));
}

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerServiceImpl();
  final List<Customer> _customers = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = "";
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
        _customers.clear();
        _currentPage = 1;
        _hasMorePages = true;
        _error = null;
      });
      _loadCustomers();
    });
  }

  Future<void> _loadCustomers() async {
    if (!_hasMorePages) return;

    try {
      final result = await _customerService.getCustomers(query: _searchQuery, page: _currentPage);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _customers.clear();
                            _currentPage = 1;
                            _hasMorePages = true;
                            _error = null;
                          });
                          _loadCustomers();
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _customers.isEmpty
                    ? Center(child: Text('Error: $_error'))
                    : _customers.isEmpty && _searchQuery.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No customers found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                              ],
                            ),
                          )
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
                              return GestureDetector(
                                onTap: () => Navigator.pop(context, customer),
                                child: Card(
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
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
