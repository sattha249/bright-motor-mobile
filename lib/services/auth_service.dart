

import 'dart:convert';

import 'package:brightmotor_store/models/auth_model.dart';
import 'package:brightmotor_store/services/session_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

final authServiceProvider = Provider.autoDispose<AuthService>((ref) {
  return AuthServiceImpl();
  return MockAuthService();
});

abstract class AuthService {

  Future<AuthResponse> login(String username, String password);

}

class MockAuthService implements AuthService {

  @override
  Future<AuthResponse> login(String username, String password) async {
    return AuthResponse(type: "bearer", token: "token");
  }
}


class AuthServiceImpl implements AuthService {

  @override
  Future<AuthResponse> login(String username, String password) async {
    final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3333';
    final url = '$baseUrl/login';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Parse the response and save the token
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      final authService = SessionPreferences();
      await authService.saveToken(authResponse);

      return authResponse;
    } else {
      throw Exception('Server error: ${response.body}');
    }
  }
}
