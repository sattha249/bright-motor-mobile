import 'product_model.dart';

class TruckResponse {
  List<Truck> data;

  TruckResponse({
    required this.data,
  });

  factory TruckResponse.fromJson(Map<String, dynamic> json) => TruckResponse(
        data: List<Truck>.from(json["data"].map((x) => Truck.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class Truck {
  int id;
  int? truckId;
  int? productId;
  int? quantity;
  String? createdAt;
  String? updatedAt;
  Product? product;

  Truck({
    required this.id,
    this.truckId,
    this.productId,
    this.quantity,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory Truck.fromJson(Map<String, dynamic> json) => Truck(
        id: json["id"],
        truckId: json["truck_id"],
        productId: json["product_id"],
        quantity: json["quantity"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        product: Product.fromJson(json["product"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "truck_id": truckId,
        "product_id": productId,
        "quantity": quantity,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "product": product?.toJson(),
      };
}
