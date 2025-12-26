import 'package:brightmotor_store/models/truck_stock_model.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/services/truck_stock_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final truckStockProvider = StateNotifierProvider.autoDispose<TruckStockNotifier, List<TruckStockItem>>((ref) {
  final service = ref.watch(truckStockServiceProvider);
  final truck = ref.watch(currentTruckProvider);
  
  // ส่ง truckId เข้าไป ถ้าไม่มี truckId ให้เป็น null
  return TruckStockNotifier(service, truck?.truckId);
});

class TruckStockNotifier extends StateNotifier<List<TruckStockItem>> {
  final TruckStockService _service;
  final int? _truckId;

  // Pagination State
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String _currentQuery = '';

  // Getters
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  TruckStockNotifier(this._service, this._truckId) : super([]) {
    if (_truckId != null) {
      loadInitial();
    }
  }

  // โหลดครั้งแรก
  Future<void> loadInitial() async {
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
    if (_truckId == null) return;

    _isLoading = true;
    try {
      final result = await _service.getStocks(
        truckId: _truckId!,
        query: query,
        page: page,
      );

      final List<TruckStockItem> newStocks = result['stocks'];
      final meta = result['meta'];

      if (isAppend) {
        state = [...state, ...newStocks];
      } else {
        state = newStocks;
      }

      _page = page;
      
      // เช็คว่ามีหน้าถัดไปไหมจาก meta
      if (meta != null) {
        final currentPage = meta['current_page'] as int;
        final lastPage = meta['last_page'] as int;
        _hasMore = currentPage < lastPage;
      } else {
        _hasMore = false;
      }

    } catch (e) {
      debugPrint("Error loading truck stocks: $e");
      _hasMore = false; // หยุดโหลดถ้า error
    } finally {
      _isLoading = false;
    }
  }
}