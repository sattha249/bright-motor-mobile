class TruckStockItem {
  final int id;
  final int truckId;
  final int quantity;
  final ProductDetail product;
  final int preOrderQuantity;
  final int availableQuantity;

  TruckStockItem({
    required this.id,
    required this.truckId,
    required this.quantity,
    required this.product,
    this.preOrderQuantity = 0,
    this.availableQuantity = 0,
  });

  TruckStockItem copyWith({
    int? id,
    int? truckId,
    int? quantity,
    ProductDetail? product,
    int? preOrderQuantity,
    int? availableQuantity,
  }) {
    return TruckStockItem(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
      preOrderQuantity: preOrderQuantity ?? this.preOrderQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  factory TruckStockItem.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] ?? 0;
    return TruckStockItem(
      id: json['id'],
      truckId: json['truck_id'],
      quantity: qty,
      product: ProductDetail.fromJson(json['product'] ?? {}),
      preOrderQuantity: 0,
      availableQuantity: qty,
    );
  }
}

class ProductDetail {
  final int id;
  final String productCode;
  final String description;
  final String sellPrice;
  final String unit;

  ProductDetail({
    required this.id,
    required this.productCode,
    required this.description,
    required this.sellPrice,
    required this.unit,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] ?? 0,
      productCode: json['product_code'] ?? '-',
      description: json['description'] ?? '-',
      sellPrice: json['sell_price'] ?? '0.00',
      unit: json['unit'] ?? '-',
    );
  }
}