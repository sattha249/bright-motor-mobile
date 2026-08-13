import 'dart:convert';
import 'package:brightmotor_store/providers/network_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final healthServiceProvider = Provider.autoDispose<HealthService>((ref) {
  return HealthServiceImpl();
});

abstract class HealthService {
  Future<bool> checkHealth();
}

class HealthServiceImpl implements HealthService {
  String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:3333';

  @override
  Future<bool> checkHealth() async {
    try {
      final url = '$baseUrl/health-check';
      final response = await defaultHttpClient()
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['online'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
