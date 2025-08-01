import 'dart:convert';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import 'session_preferences.dart';

abstract class CustomerService {
  Future<Map<String, dynamic>> getCustomers({int page = 1});
}

class MockCustomerService extends CustomerService {
  @override
  Future<Map<String, dynamic>> getCustomers({int page = 1}) async {
    return {
      'customers': [
        Customer(
          id: 1,
          email: 'john.doe@example.com',
          customerNo: 'CUS-1234',
          name: 'Test Example',
          tel: '0812345678',
          address: '12/23',
          district: 'Test Dist',
          province: 'Test PRovic',
          postCode: '12345',
          country: 'TH',
        ),
      ],
      'meta': {
        'total': 1,
        'perPage': 1,
        'currentPage': 1,
        'lastPage': 1,
        'firstPage': 1,
        'firstPageUrl': 'http://localhost:3333/customers?page=1',
        'lastPageUrl': 'http://localhost:3333/customers?page=1',
        'nextPageUrl': null,
        'previousPageUrl': null,
      },
    };
  }
}

class CustomerServiceImpl extends CustomerService {
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3333';

  final SessionPreferences _authService = SessionPreferences();

  @override
  Future<Map<String, dynamic>> getCustomers({int page = 1}) async {
    try {
      final token = await _authService.getToken();
      final response = await defaultHttpClient().get(
        Uri.parse('$baseUrl/customers?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Customer> customers = (data['data'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();

        return {
          'customers': customers,
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
