import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/services/product_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SystemProductState {
  final List<Product> products;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final String query;

  SystemProductState({
    this.products = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.query = '',
  });

  SystemProductState copyWith({
    List<Product>? products,
    int? page,
    bool? hasMore,
    bool? isLoading,
    String? query,
  }) {
    return SystemProductState(
      products: products ?? this.products,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
    );
  }
}

final systemProductProvider = StateNotifierProvider.autoDispose<SystemProductNotifier, SystemProductState>((ref) {
  final service = ref.watch(productServiceProvider);
  return SystemProductNotifier(service);
});

class SystemProductNotifier extends StateNotifier<SystemProductState> {
  final ProductService _service;
  final int _perPage = 20;

  SystemProductNotifier(this._service) : super(SystemProductState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    await fetchData(page: 1, query: '');
  }

  Future<void> search(String query) async {
    await fetchData(page: 1, query: query);
  }

  Future<void> nextPage() async {
    if (state.isLoading || !state.hasMore) return;
    await fetchData(page: state.page + 1, query: state.query);
  }

  Future<void> previousPage() async {
    if (state.isLoading || state.page <= 1) return;
    await fetchData(page: state.page - 1, query: state.query);
  }

  Future<void> fetchData({
    required int page,
    required String query,
  }) async {
    state = state.copyWith(isLoading: true, query: query);

    try {
      final response = await _service.getSystemProducts(
        page: page,
        perPage: _perPage,
        search: query,
      );

      final newProducts = response.data;
      
      state = state.copyWith(
        products: newProducts,
        page: page,
        hasMore: newProducts.length >= _perPage,
        isLoading: false,
      );
    } catch (e) {
      debugPrint("Error fetching system products: $e");
      state = state.copyWith(
        products: [],
        hasMore: false,
        isLoading: false,
      );
    }
  }
}
