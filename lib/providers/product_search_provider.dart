import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/product_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final productSearchProvider = StateNotifierProvider.autoDispose<ProductSearchNotifier, List<Product>>((ref) {
  final service = ref.watch(productServiceProvider);
  return ProductSearchNotifier(service);
});

class ProductSearchNotifier extends StateNotifier<List<Product>> {
  final ProductService _service;

  // --- ส่วนที่เพิ่มสำหรับ Pagination ---
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String _currentQuery = '';

  // Getters เพื่อให้ UI เรียกใช้ได้ (แก้ Error hasMore, isLoading)
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  // --------------------------------

  ProductSearchNotifier(this._service) : super([]);

  // ฟังก์ชันค้นหา (เริ่มหน้า 1 ใหม่)
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

    // เคลียร์ข้อมูลเก่าเพื่อให้ UI รู้ว่ากำลังค้นหาใหม่ (หรือจะเก็บไว้ก่อนก็ได้)
    state = [];

    try {
      // เรียก Service หน้า 1
      final response = await _service.search(query, page: 1, limit: 20);
      state = response.data;
      
      // เช็คว่ามีหน้าต่อไปไหม (ถ้าข้อมูลที่ได้น้อยกว่า limit 20 แสดงว่าหมดแล้ว)
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

  // ฟังก์ชันโหลดหน้าถัดไป (แก้ Error fetchNextPage)
  Future<void> fetchNextPage() async {
    // ถ้ากำลังโหลดอยู่, ไม่มีข้อมูลแล้ว, หรือไม่มีคำค้นหา ไม่ต้องทำอะไร
    if (_isLoading || !_hasMore || _currentQuery.isEmpty) return;

    _isLoading = true;

    try {
      final nextPage = _page + 1;
      // เรียก Service หน้าถัดไป
      final response = await _service.search(_currentQuery, page: nextPage, limit: 20);

      if (response.data.isEmpty) {
        _hasMore = false;
      } else {
        _page = nextPage;
        // เอาข้อมูลใหม่มาต่อท้ายข้อมูลเดิม (Append)
        state = [...state, ...response.data]; 
        
        if (response.data.length < 20) {
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