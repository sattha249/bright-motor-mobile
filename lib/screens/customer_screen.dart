import 'package:brightmotor_store/screens/customer/customer_form_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/customer.dart';
import '../services/customer_service.dart';

Future<Customer?> launchCustomerChooser(BuildContext context) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => const CustomerScreen(isSelectionMode: true),
    fullscreenDialog: true
  ));
}

class CustomerScreen extends StatefulWidget {
  final bool isSelectionMode;

  const CustomerScreen({super.key, this.isSelectionMode = false});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final CustomerService _customerService = CustomerServiceImpl();
  final List<Customer> _customers = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
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
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadCustomers();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
        _customers.clear();
        _currentPage = 1;
        _hasMorePages = true;
        _error = null;
        _isLoading = true;
      });
      _loadCustomers();
    });
  }

  void _refreshList() {
    setState(() {
      _customers.clear();
      _currentPage = 1;
      _hasMorePages = true;
      _error = null;
      _isLoading = true;
    });
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!_hasMorePages && !_isLoading) return;

    try {
      final result = await _customerService.getCustomers(query: _searchQuery, page: _currentPage);
      
      if (mounted) {
        setState(() {
          // [แก้ไข] ไม่ต้อง .map(...fromJson) ซ้ำ เพราะ Service แปลงมาให้แล้ว
          // ใช้ .cast<Customer>() เพื่อระบุ Type ให้ชัดเจน
          final List<Customer> newItems = (result['customers'] as List).cast<Customer>();
          
          _customers.addAll(newItems);
          
          // ดึง Meta Data
          final meta = result['meta'];
          if (meta != null) {
             // เช็คว่ามีหน้าถัดไปไหม (logic ตาม API ของคุณ)
             final lastPage = meta['last_page'] ?? 1;
             final currentPage = meta['current_page'] ?? 1;
             _hasMorePages = currentPage < lastPage;
          } else {
             _hasMorePages = false;
          }
          
          if (newItems.isNotEmpty) _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading customers: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'เลือกลูกค้า' : 'จัดการลูกค้า'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหา (ชื่อ, เบอร์โทร)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
                      );
                      if (result == true) {
                        _refreshList();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            // ถ้ามี Error ให้โชว์ Error ด้วย จะได้รู้ว่าพังตรงไหน
                            Text(_error != null ? 'Error: $_error' : 'ไม่พบข้อมูลลูกค้า', 
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _customers.length + (_hasMorePages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _customers.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                          }

                          final customer = _customers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(customer.name.isNotEmpty ? customer.name[0] : "?"),
                              ),
                              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${customer.customerNo} | โทร: ${customer.tel}'),
                                  if (customer.address.isNotEmpty)
                                    Text('${customer.address} ${customer.district} ${customer.province}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                              onTap: () {
                                if (widget.isSelectionMode) {
                                  Navigator.pop(context, customer);
                                }
                              },
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