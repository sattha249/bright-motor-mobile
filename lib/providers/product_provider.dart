import 'package:brightmotor_store/database/daos/user_dao.dart';
import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/providers/truck_provider.dart';
import 'package:brightmotor_store/services/product_service.dart';
import 'package:brightmotor_store/services/truck_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final currentTruckIdProvider = Provider.autoDispose<int?>((ref) {
  return ref.watch(currentTruckProvider.select((value) => value?.truckId));
});

final productsProvider =
    StateNotifierProvider.autoDispose<ProductNotifier, List<Product>>((ref) {
  final truckId = ref.watch(currentTruckIdProvider);
  return ProductNotifier(
    service: ref.watch(productServiceProvider),
    truckService: ref.watch(truckServiceProvider),
    truckId: truckId,
  )..reload();
});

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
  final UserDao _userDao = UserDao();

  List<Product> _originProducts = [];

  ProductNotifier({
    required this.service,
    required this.truckService,
    this.truckId,
  }) : super([]);

  void reload() async {
    int? activeTruckId = truckId;
    if (activeTruckId == null || activeTruckId <= 0) {
      final user = await _userDao.getActiveUser();
      activeTruckId = user?.truckId;
    }

    if (activeTruckId != null && activeTruckId > 0) {
      try {
        final response = await truckService.getTruckStocks(activeTruckId, limit: 300);
        
        final data = response.data
            .where((stockItem) => stockItem.product != null) 
            .map((stockItem) {
              final product = stockItem.product!; 
              return product.copyWith(quantity: stockItem.quantity);
            }).toList();

        _originProducts = data;
        state = data;
      } catch (e) {
        debugPrint("Error loading products: $e");
      }
    }
  }

  void search(String query) async {
    if (query.isNotEmpty) {
      state = _originProducts.where((p) => p.description.contains(query)).toList();
    } else {
      state = _originProducts;
    }
  }
}

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