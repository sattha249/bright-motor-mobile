import 'package:brightmotor_store/models/pre_order_model.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/services/pre_order_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final preOrderProvider = StateNotifierProvider.autoDispose<PreOrderNotifier, List<PreOrder>>((ref) {
  final service = ref.watch(preOrderServiceProvider);
  final truck = ref.watch(currentTruckProvider);
  return PreOrderNotifier(service, truck?.truckId);
});

class PreOrderNotifier extends StateNotifier<List<PreOrder>> {
  final PreOrderService _service;
  final int? _truckId;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  PreOrderNotifier(this._service, this._truckId) : super([]) {
    if (_truckId != null) loadInitial();
  }

  Future<void> loadInitial() async {
    _page = 1;
    _hasMore = true;
    state = [];
    await fetchData();
  }

  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;
    _page++;
    await fetchData(isAppend: true);
  }

  Future<void> fetchData({bool isAppend = false}) async {
    if (_truckId == null) return;
    
    _isLoading = true;
    try {
      final result = await _service.getPreOrders(truckId: _truckId!, page: _page);
      
      final List<PreOrder> newItems = result['data'];
      final meta = result['meta'];

      if (isAppend) {
        state = [...state, ...newItems];
      } else {
        state = newItems;
      }

      if (meta != null) {
        final currentPage = meta['current_page'] as int;
        final lastPage = meta['last_page'] as int;
        _hasMore = currentPage < lastPage;
      } else {
        _hasMore = false;
      }

    } catch (e) {
      debugPrint("Error loading pre-orders: $e");
      _hasMore = false;
    } finally {
      _isLoading = false;
    }
  }
}