import 'package:flutter/material.dart';
import '../components/login_component.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  // Mock credentials
  static const String _mockUsername = 'admin';
  static const String _mockPassword = 'password123';

  void _handleLogin(BuildContext context, String username, String password) {
    if (username == _mockUsername && password == _mockPassword) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(username: username),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid username or password'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                onLogin: (username, password) => _handleLogin(
                  context,
                  username,
                  password,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hint: Use admin/password123',
                style: TextStyle(
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