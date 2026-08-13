import 'dart:convert';
import 'package:brightmotor_store/database/daos/customer_dao.dart';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/customer.dart';
import 'session_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final customerServiceProvider = Provider.autoDispose<CustomerService>((ref) {
  return CustomerServiceImpl();
});

abstract class CustomerService {
  Future<Map<String, dynamic>> getCustomers({required String query, int page = 1});
  Future<void> createCustomer(Customer customer);
}

class MockCustomerService extends CustomerService {
  @override
  Future<Map<String, dynamic>> getCustomers({required String query, int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 500)); 
    
    return {
      'customers': [
        Customer(
          id: 1,
          email: 'john.doe@example.com',
          customerNo: 'CUS-1234',
          name: 'Test Example (Mock)',
          tel: '0812345678',
          address: '12/23',
          district: 'Test Dist',
          province: 'Test Provic',
          postCode: '12345',
          country: 'TH',
        ),
      ],
      'meta': {
        'total': 1,
        'per_page': 10,
        'current_page': 1,
        'last_page': 1,
      },
    };
  }

  @override
  Future<void> createCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }
}

class CustomerServiceImpl extends CustomerService {
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';
  final SessionPreferences _authService = SessionPreferences();
  final CustomerDao _customerDao = CustomerDao();

  @override
  Future<Map<String, dynamic>> getCustomers({required String query, int page = 1}) async {
    try {
      final token = await _authService.getToken();

      final Map<String, String> queryParams = {
        'page': page.toString(),
      };
      
      if (query.isNotEmpty) {
        queryParams['search'] = query;
      }

      final uri = Uri.parse('$baseUrl/customers').replace(queryParameters: queryParams);

      final response = await defaultHttpClient().get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> jsonList = data['data'] ?? []; 
        
        final List<Customer> customers = jsonList
            .map((json) => Customer.fromJson(json))
            .toList();

        // Also cache server results into local SQLite
        await _customerDao.insertOrUpdateBatch(customers);

        return {
          'customers': customers,
          'meta': data['meta'],
        };
      }
    } catch (e) {
      debugPrint('Online customer fetch failed, falling back to SQLite: $e');
    }

    // --- Fallback: Read from Local SQLite DB ---
    final localCustomers = await _customerDao.getAllCustomers(query: query);
    return {
      'customers': localCustomers,
      'meta': {
        'total': localCustomers.length,
        'per_page': localCustomers.isNotEmpty ? localCustomers.length : 10,
        'current_page': 1,
        'last_page': 1,
      },
    };
  }

  @override
  Future<void> createCustomer(Customer customer) async {
    try {
      final token = await _authService.getToken();
      final url = '$baseUrl/customers';

      final response = await defaultHttpClient().post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(customer.toJson()),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      // Save customer to local SQLite if offline
      await _customerDao.insertOrUpdateBatch([customer]);
    }
  }
}