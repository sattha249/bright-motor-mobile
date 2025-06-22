import 'package:brightmotor_store/models/truck_info.dart';
import 'package:brightmotor_store/services/truck_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final currentTruckProvider = StateNotifierProvider.autoDispose<TruckNotifier, TruckInfo?>((ref) {
  return TruckNotifier(ref.watch(truckServiceProvider))..reload();
});

class TruckNotifier extends StateNotifier<TruckInfo?> {
  final TruckService service;

  TruckNotifier(this.service) : super(null);

  void reload() {
    service.getTruckInfo().then((value) {
      state = value;
    });
  }

}
