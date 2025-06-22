import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/product_service.dart';
import 'package:brightmotor_store/services/truck_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final productsProvider = StateNotifierProvider.autoDispose
    .family<ProductNotifier, List<Product>, int?>((ref, truckId) {
  return ProductNotifier(
    service: ref.read(productServiceProvider),
    truckService: ref.read(truckServiceProvider),
    truckId: truckId,
  )..reload();
});

final productCategoriesProvider =
    Provider.autoDispose.family<Map<String, int>, int?>((ref, truckId) {
  final products = ref.watch(productsProvider(truckId));
  final categoryCounts = <String, int>{};

  categoryCounts["ทั้งหมด"] = products.length;
  for (var product in products) {
    categoryCounts[product.category] =
        (categoryCounts[product.category] ?? 0) + 1;
  }

  return categoryCounts;
});

final productByCategoriesProvider = Provider.autoDispose
    .family<List<Product>, ProductCategoryParams>((ref, params) {
  final products = ref.watch(productsProvider(params.truckId));
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

  ProductNotifier(
      {required this.service, required this.truckService, this.truckId})
      : super([]);

  void reload() {
    //TODO: switch it with truck service once it has data.
    service.getProducts().then((value) {
      state = value.data;
    });
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
