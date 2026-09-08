import 'package:brightmotor_store/database/daos/user_dao.dart';
import 'package:brightmotor_store/models/truck_stock_model.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/services/pre_order_service.dart';
import 'package:brightmotor_store/services/truck_stock_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final truckStockProvider = StateNotifierProvider.autoDispose<TruckStockNotifier, List<TruckStockItem>>((ref) {
  final service = ref.watch(truckStockServiceProvider);
  final preOrderService = ref.watch(preOrderServiceProvider);
  final truck = ref.watch(currentTruckProvider);
  
  return TruckStockNotifier(service, preOrderService, truck?.truckId);
});

class TruckStockNotifier extends StateNotifier<List<TruckStockItem>> {
  final TruckStockService _service;
  final PreOrderService _preOrderService;
  final int? _truckId;
  final UserDao _userDao = UserDao();

  Map<int, int> _preOrderQuantities = {};
  bool _isPreOrderLoaded = false;

  // Pagination State
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String _currentQuery = '';

  // Getters
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  TruckStockNotifier(this._service, this._preOrderService, this._truckId) : super([]) {
    loadInitial();
  }

  // โหลดครั้งแรก
  Future<void> loadInitial() async {
    _preOrderQuantities = {};
    _isPreOrderLoaded = false;
    await fetchData(page: 1, query: '');
  }

  // ค้นหา (Reset ไปหน้า 1)
  Future<void> search(String query) async {
    _currentQuery = query;
    await fetchData(page: 1, query: query);
  }

  // โหลดหน้าถัดไป (Append)
  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;
    await fetchData(page: _page + 1, query: _currentQuery, isAppend: true);
  }

  // Logic กลางในการดึงข้อมูล
  Future<void> fetchData({required int page, required String query, bool isAppend = false}) async {
    int? activeTruckId = _truckId;
    if (activeTruckId == null || activeTruckId <= 0) {
      final user = await _userDao.getActiveUser();
      activeTruckId = user?.truckId;
    }

    if (activeTruckId == null || activeTruckId <= 0) {
      _isLoading = false;
      return;
    }

    _isLoading = true;
    try {
      if (!_isPreOrderLoaded) {
        _preOrderQuantities = await _preOrderService.getPreOrderQuantities(truckId: activeTruckId);
        _isPreOrderLoaded = true;
      }

      final result = await _service.getStocks(
        truckId: activeTruckId,
        query: query,
        page: page,
      );

      final List<TruckStockItem> rawStocks = result['stocks'];
      final List<TruckStockItem> newStocks = rawStocks.map((stock) {
        final preOrderQty = _preOrderQuantities[stock.product.id] ?? 0;
        final availableQty = stock.quantity - preOrderQty;
        return stock.copyWith(
          preOrderQuantity: preOrderQty,
          availableQuantity: availableQty,
        );
      }).toList();

      final meta = result['meta'];

      if (isAppend) {
        state = [...state, ...newStocks];
      } else {
        state = newStocks;
      }

      _page = page;
      
      if (meta != null) {
        final currentPage = meta['current_page'] as int;
        final lastPage = meta['last_page'] as int;
        _hasMore = currentPage < lastPage;
      } else {
        _hasMore = false;
      }

    } catch (e) {
      debugPrint("Error loading truck stocks: $e");
      _hasMore = false;
    } finally {
      _isLoading = false;
    }
  }
}
