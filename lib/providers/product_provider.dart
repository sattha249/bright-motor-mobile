import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/services/product_service.dart';
import 'package:brightmotor_store/services/truck_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ... (currentTruckIdProvider เหมือนเดิม) ...
final currentTruckIdProvider = Provider.autoDispose<int?>((ref) {
  return ref.watch(currentTruckProvider.select((value) => value?.truckId));
});

// ... (productsProvider ปรับปรุง) ...
final productsProvider =
    StateNotifierProvider.autoDispose<ProductNotifier, List<Product>>((ref) {
  
  // [แก้ไข] ต้องใช้ ref.watch เท่านั้น! เพื่อให้ Provider สร้างใหม่เมื่อ truckId เปลี่ยน
  // จากเดิม: final truckId = ref.read(currentTruckIdProvider); 
  final truckId = ref.watch(currentTruckIdProvider); 

  print("DEBUG: productsProvider created with Truck ID: $truckId"); // ใส่ Log เช็ค

  return ProductNotifier(
    service: ref.watch(productServiceProvider),
    truckService: ref.watch(truckServiceProvider),
    truckId: truckId,
  )..reload();
});

// ... (productCategoriesProvider เหมือนเดิม) ...
final productCategoriesProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final products = ref.watch(productsProvider);
  final categoryCounts = <String, int>{};

  if (products.isNotEmpty) {
    categoryCounts["ทั้งหมด"] = products.length;
  }
  for (var product in products) {
    categoryCounts[product.category] =
        (categoryCounts[product.category] ?? 0) + 1;
  }

  return categoryCounts;
});

// ... (productByCategoriesProvider เหมือนเดิม) ...
final productByCategoriesProvider = Provider.autoDispose
    .family<List<Product>, ProductCategoryParams>((ref, params) {
  final products = ref.watch(productsProvider);
  if (params.category == null || params.category == "ทั้งหมด") {
    return products;
  } else {
    return products
        .where((product) => product.category == params.category)
        .toList();
  }
});

class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductService service;
  final TruckService truckService;
  final int? truckId;

  // Pagination State
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isSearching = false; // เช็คว่ากำลังอยู่ในโหมดค้นหาหรือไม่

  // Getters เพื่อให้ UI ตรวจสอบสถานะได้
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  ProductNotifier({
    required this.service,
    required this.truckService,
    this.truckId,
  }) : super([]);

  // โหลดข้อมูลเริ่มต้น (หน้า 1)
  Future<void> reload() async {
    if (truckId == null) return;
    
    _isSearching = false; // ออกจากโหมดค้นหา
    _page = 1;
    _hasMore = true;
    _isLoading = true;
    state = []; // เคลียร์ข้อมูลเก่าก่อนโหลดใหม่

    try {
      // ส่ง page: 1 ไปที่ service
      await _fetchData(page: 1);
    } catch (e) {
      debugPrint("Error reloading products: $e");
    } finally {
      _isLoading = false;
    }
  }

  // โหลดหน้าถัดไป (Infinite Scroll)
  Future<void> fetchNextPage() async {
    // ถ้ากำลังโหลดอยู่, ไม่มีข้อมูลแล้ว, หรือกำลังค้นหาอยู่ ไม่ต้องโหลดต่อ
    if (_isLoading || !_hasMore || _isSearching || truckId == null) return;

    _isLoading = true;
    try {
      await _fetchData(page: _page + 1);
    } catch (e) {
      debugPrint("Error fetching next page: $e");
    } finally {
      _isLoading = false;
    }
  }

  // Logic การดึงข้อมูลจริงจาก API
  Future<void> _fetchData({required int page}) async {
    // สมมติว่า getTruckStocks รับ parameter page ได้
    // คุณต้องไปแก้ที่ TruckService ให้รับ page ด้วย
    final response = await truckService.getTruckStocks(truckId!, page: page);
    
    final newProducts = response.data
        .map((event) => event.product)
        .nonNulls
        .toSet()
        .toList();

    if (newProducts.isEmpty) {
      _hasMore = false;
    } else {
      // ถ้าข้อมูลที่ได้น้อยกว่า limit (เช่น 10) แปลว่าหมดแล้ว
      // (ต้องเช็คกับ API meta ของคุณดูว่ามี total_pages หรือ last_page ไหม)
      if (response.data.length < 10) { 
         _hasMore = false;
      }
      
      _page = page;
      // เอาของใหม่ต่อท้ายของเดิม
      state = [...state, ...newProducts];
    }
  }

  // ค้นหาสินค้า
  void search(String query) async {
    print("search($query)");
    if (query.isEmpty) {
      // ถ้าลบคำค้นหาจนหมด ให้กลับไปโหลด Stock ปกติ
      reload();
    } else {
      _isSearching = true;
      _isLoading = true;
      state = []; // เคลียร์หน้าจอระหว่างค้นหา
      
      try {
        final result = await service.search(query);
        print(result.data);
        state = result.data;
        _hasMore = false; // การค้นหา (แบบนี้) มักจะไม่มี pagination ต่อ
      } catch (e) {
        debugPrint("Search error: $e");
      } finally {
        _isLoading = false;
      }
    }
  }
}

// ... (ProductCategoryParams เหมือนเดิม) ...
class ProductCategoryParams {
  final int? truckId;
  final String? category;

  ProductCategoryParams({this.truckId, this.category});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductCategoryParams &&
        other.truckId == truckId &&
        other.category == category;
  }

  @override
  int get hashCode {
    return truckId.hashCode ^ category.hashCode;
  }
}