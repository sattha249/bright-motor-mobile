import 'package:brightmotor_store/database/daos/user_dao.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/providers/product_provider.dart';
import 'package:brightmotor_store/services/pre_order_service.dart';
import 'package:brightmotor_store/services/product_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final productSearchProvider = StateNotifierProvider.autoDispose<ProductSearchNotifier, List<Product>>((ref) {
  final service = ref.watch(productServiceProvider);
  final preOrderService = ref.watch(preOrderServiceProvider);
  final truckId = ref.watch(currentTruckIdProvider);
  return ProductSearchNotifier(service, preOrderService, truckId);
});

class ProductSearchNotifier extends StateNotifier<List<Product>> {
  final ProductService _service;
  final PreOrderService _preOrderService;
  final int? _truckId;
  final UserDao _userDao = UserDao();

  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String _currentQuery = '';
  Map<int, int> _preOrderQuantities = {};

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  ProductSearchNotifier(this._service, this._preOrderService, this._truckId) : super([]);

  Future<int?> _getActiveTruckId() async {
    int? activeTruckId = _truckId;
    if (activeTruckId == null || activeTruckId <= 0) {
      final user = await _userDao.getActiveUser();
      activeTruckId = user?.truckId;
    }
    return activeTruckId;
  }

  Future<List<Product>> _mapWithPreOrders(List<Product> products) async {
    final activeTruckId = await _getActiveTruckId();
    if (activeTruckId != null && activeTruckId > 0) {
      if (_preOrderQuantities.isEmpty) {
        _preOrderQuantities = await _preOrderService.getPreOrderQuantities(truckId: activeTruckId);
      }
    }
    return products.map((p) {
      final poQty = _preOrderQuantities[p.id] ?? 0;
      final availQty = p.quantity - poQty;
      return p.copyWith(
        preOrderQuantity: poQty,
        availableQuantity: availQty,
      );
    }).toList();
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    _page = 1;
    _hasMore = true;
    _isLoading = true;
    
    if (query.isEmpty) {
      state = [];
      _isLoading = false;
      _hasMore = false;
      return;
    }

    state = [];

    try {
      final response = await _service.search(query, page: 1, limit: 20);
      state = await _mapWithPreOrders(response.data);
      
      if (response.data.length < 20) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Search Error: $e");
      _hasMore = false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore || _currentQuery.isEmpty) return;

    _isLoading = true;

    try {
      final nextPage = _page + 1;
      final response = await _service.search(_currentQuery, page: nextPage, limit: 20);
      final newData = await _mapWithPreOrders(response.data);

      if (newData.isEmpty) {
        _hasMore = false;
      } else {
        _page = nextPage;
        state = [...state, ...newData];
        
        if (newData.length < 20) {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint("Fetch Next Page Error: $e");
      _hasMore = false;
    } finally {
      _isLoading = false;
    }
  }
}
