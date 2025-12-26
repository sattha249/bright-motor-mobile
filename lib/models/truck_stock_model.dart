class TruckStockItem {
  final int id;
  final int truckId;
  final int quantity;
  final ProductDetail product;

  TruckStockItem({
    required this.id,
    required this.truckId,
    required this.quantity,
    required this.product,
  });

  factory TruckStockItem.fromJson(Map<String, dynamic> json) {
    return TruckStockItem(
      id: json['id'],
      truckId: json['truck_id'],
      quantity: json['quantity'] ?? 0,
      product: ProductDetail.fromJson(json['product'] ?? {}),
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