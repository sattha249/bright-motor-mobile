import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/product_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final productSearchProvider = StateNotifierProvider.autoDispose<ProductSearchNotifier, List<Product>>((ref) {
  final service = ref.read(productServiceProvider);
  return ProductSearchNotifier(service);
});


class ProductSearchNotifier extends StateNotifier<List<Product>> {
  final ProductService service;
  ProductSearchNotifier(this.service) : super([]);

  void search(String query) async {
    try {
      final response = await service.search(query);
      state = response.data;
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
    }
  }


}
