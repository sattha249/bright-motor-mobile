import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import 'auth_service.dart';

class CustomerService {
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3333';

  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getCustomers({int page = 1}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
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