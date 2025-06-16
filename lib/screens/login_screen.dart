import 'package:brightmotor_store/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../components/login_component.dart';
import 'welcome_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/auth_model.dart';
import '../services/session_preferences.dart';
import '../screens/main_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _currentUsername = '';
  String _currentPassword = '';

  void _onInputChanged(String username, String password) {
    setState(() {
      _currentUsername = username;
      _currentPassword = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authApi = ref.watch(authServiceProvider);
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
                onLogin: (username, password) async {
                  try {
                    final authResponse = await authApi.login(username, password);
                    await SessionPreferences().saveToken(authResponse);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainLayout(),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
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