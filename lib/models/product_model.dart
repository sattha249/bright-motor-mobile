class Product {
  final int id;
  final String category;
  final String description;
  final String brand;
  final String model;
  final String costPrice;
  final String sellPrice;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.category,
    required this.description,
    required this.brand,
    required this.model,
    required this.costPrice,
    required this.sellPrice,
    required this.unit,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      category: json['category'] as String,
      description: json['description'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      costPrice: json['cost_price'] as String,
      sellPrice: json['sell_price'] as String,
      unit: json['unit'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

class ProductResponse {
  final Meta meta;
  final List<Product> data;

  ProductResponse({
    required this.meta,
    required this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      meta: Meta.fromJson(json['meta']),
      data: (json['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
    );
  }
}

class Meta {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int firstPage;
  final String firstPageUrl;
  final String lastPageUrl;
  final String? nextPageUrl;
  final String? previousPageUrl;

  Meta({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.firstPage,
    required this.firstPageUrl,
    required this.lastPageUrl,
    this.nextPageUrl,
    this.previousPageUrl,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      total: json['total'] as int,
      perPage: json['per_page'] as int,
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      firstPage: json['first_page'] as int,
      firstPageUrl: json['first_page_url'] as String,
      lastPageUrl: json['last_page_url'] as String,
      nextPageUrl: json['next_page_url'] as String?,
      previousPageUrl: json['previous_page_url'] as String?,
    );
  }
} 