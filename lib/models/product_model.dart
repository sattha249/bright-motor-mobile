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
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 10,
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      firstPage: json['first_page'] as int? ?? 1,
      firstPageUrl: json['first_page_url'] as String? ?? '',
      lastPageUrl: json['last_page_url'] as String? ?? '',
      nextPageUrl: json['next_page_url'] as String?,
      previousPageUrl: json['previous_page_url'] as String?,
    );
  }
}

class Product {
  final int id;
  final String category;
  final String description;
  final String brand;
  final String model;
  final String costPrice;
  final String sellPrice;
  final String unit;
  final int quantity;
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
    this.quantity = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      costPrice: json['cost_price'] as String? ?? '0',
      sellPrice: json['sell_price'] as String? ?? '0',
      unit: json['unit'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // [เพิ่ม] เมธอดนี้ที่หายไป ทำให้ truck_response.dart แดง
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'brand': brand,
      'model': model,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'unit': unit,
      'quantity': quantity,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Product copyWith({int? quantity}) {
    return Product(
      id: id,
      category: category,
      description: description,
      brand: brand,
      model: model,
      costPrice: costPrice,
      sellPrice: sellPrice,
      unit: unit,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Product &&
        other.id == id &&
        other.category == category &&
        other.description == description &&
        other.brand == brand &&
        other.model == model &&
        other.costPrice == costPrice &&
        other.sellPrice == sellPrice &&
        other.unit == unit &&
        other.quantity == quantity &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        category.hashCode ^
        description.hashCode ^
        brand.hashCode ^
        model.hashCode ^
        costPrice.hashCode ^
        sellPrice.hashCode ^
        unit.hashCode ^
        quantity.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}