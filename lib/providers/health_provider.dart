import 'dart:async';
import 'package:brightmotor_store/services/health_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HealthState {
  final bool isOnline;
  final bool isChecking;
  final DateTime? lastChecked;

  HealthState({
    this.isOnline = true,
    this.isChecking = false,
    this.lastChecked,
  });

  HealthState copyWith({
    bool? isOnline,
    bool? isChecking,
    DateTime? lastChecked,
  }) {
    return HealthState(
      isOnline: isOnline ?? this.isOnline,
      isChecking: isChecking ?? this.isChecking,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

class HealthNotifier extends StateNotifier<HealthState> {
  final HealthService _healthService;
  Timer? _timer;

  HealthNotifier(this._healthService) : super(HealthState()) {
    checkHealth();
    // Periodically check server health every 20 seconds
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      checkHealth();
    });
  }

  Future<bool> checkHealth() async {
    if (state.isChecking) return state.isOnline;

    state = state.copyWith(isChecking: true);
    final isOnline = await _healthService.checkHealth();
    
    state = state.copyWith(
      isOnline: isOnline,
      isChecking: false,
      lastChecked: DateTime.now(),
    );

    return isOnline;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  final service = ref.watch(healthServiceProvider);
  return HealthNotifier(service);
});
