import 'dart:convert';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/customer.dart';
import 'session_preferences.dart';

abstract class CustomerService {
  Future<Map<String, dynamic>> getCustomers({required String query, int page = 1});
  Future<void> createCustomer(Customer customer);
}

class MockCustomerService extends CustomerService {
  @override
  Future<Map<String, dynamic>> getCustomers({required String query, int page = 1}) async {
    // จำลอง Delay เพื่อให้เห็น Loading
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
        'per_page': 10, // แก้ key ให้ตรงกับ API จริง (snake_case)
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
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3333';
  final SessionPreferences _authService = SessionPreferences();

  @override
  Future<Map<String, dynamic>> getCustomers({required String query, int page = 1}) async {
    try {
      final token = await _authService.getToken();

      // 1. สร้าง Query Parameters แบบรวมศูนย์ (ไม่ต้องแยก if/else)
      final Map<String, String> queryParams = {
        'page': page.toString(),
      };
      
      // ถ้ามีคำค้นหา ให้เพิ่มเข้าไป
      if (query.isNotEmpty) {
        queryParams['search'] = query;
      }

      // 2. สร้าง URI ที่ถูกต้อง (รองรับภาษาไทยและอักขระพิเศษ)
      final uri = Uri.parse('$baseUrl/customers').replace(queryParameters: queryParams);

      final response = await defaultHttpClient().get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // ควรใส่ Accept ด้วย
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 3. ดัก Null Safety: กรณี data['data'] เป็น null ให้ใช้ [] แทน
        final List<dynamic> jsonList = data['data'] ?? []; 
        
        final List<Customer> customers = jsonList
            .map((json) => Customer.fromJson(json))
            .toList();

        // ส่งกลับในรูปแบบ Map ที่ UI รอรับ
        return {
          'customers': customers,
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting customers: $e');
    }
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
      );

      // ยอมรับทั้ง 200 และ 201 (Created)
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }
}