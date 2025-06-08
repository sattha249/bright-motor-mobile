import 'package:flutter/material.dart';
import '../components/login_component.dart';
import 'welcome_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../screens/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _currentUsername = '';
  String _currentPassword = '';
  final _authService = AuthService();

  Future<void> _handleLogin(String username, String password) async {
    try {
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3333';
      final url = '$baseUrl/login';
      print('Attempting login to: $url');
      
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse the response and save the token
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _authService.saveToken(authResponse);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainLayout(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Login error details: $e');
      if (e is http.ClientException) {
        print('Connection error details: ${e.message}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onInputChanged(String username, String password) {
    setState(() {
      _currentUsername = username;
      _currentPassword = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              LoginComponent(
                onLogin: _handleLogin,
                onInputChanged: _onInputChanged,
              ),
              const SizedBox(height: 16),
              Text(
                'Current Input: $_currentUsername / $_currentPassword',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 