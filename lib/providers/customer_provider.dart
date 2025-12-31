import 'package:brightmotor_store/models/customer_model.dart';
import 'package:brightmotor_store/services/customer_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// State สำหรับเก็บข้อมูล List
class CustomerState {
  final List<Customer> customers;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String searchKeyword;

  CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.searchKeyword = '',
  });

  CustomerState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? searchKeyword,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerService _service;

  CustomerNotifier(this._service) : super(CustomerState());

  Future<void> fetchCustomers({bool refresh = false, String? search}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true, 
        currentPage: 1, 
        customers: [], 
        hasMore: true,
        searchKeyword: search ?? state.searchKeyword
      );
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _service.getCustomers(
        page: state.currentPage,
        search: state.searchKeyword,
      );

      final newCustomers = response.data;
      final meta = response.meta;

      state = state.copyWith(
        isLoading: false,
        customers: [...state.customers, ...newCustomers],
        currentPage: state.currentPage + 1,
        hasMore: meta != null ? state.currentPage < meta.lastPage : false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print("Error fetching customers: $e");
    }
  }

  void search(String keyword) {
    fetchCustomers(refresh: true, search: keyword);
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  final service = ref.watch(customerServiceProvider);
  return CustomerNotifier(service);
});