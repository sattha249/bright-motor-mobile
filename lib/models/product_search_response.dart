

import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/models/truck_response.dart';

class ProductSearchResponse {
  final Meta meta;
  final List<Truck> data;


  ProductSearchResponse({
    required this.meta,
    required this.data,
  });

  factory ProductSearchResponse.fromJson(Map<String, dynamic> json) {
    return ProductSearchResponse(
      meta: Meta.fromJson(json['meta']),
      data: (json['data'] as List)
          .map((item) => Truck.fromJson(item))
          .toList(),
    );
  }
}