import 'package:brightmotor_store/models/product_model.dart';
import 'package:brightmotor_store/models/truck_response.dart';

class ProductSearchResponse {
  final Meta meta;
  final List<Product> data;

  ProductSearchResponse({
    required this.meta,
    required this.data,
  });

  factory ProductSearchResponse.fromJson(Map<String, dynamic> json) {
    return ProductSearchResponse(
      meta: Meta.fromJson(json['meta']),
      
      // [จุดสำคัญที่ต้องแก้] 
      // เปลี่ยนจากการ map item ตรงๆ เป็นการดึง item['product']
      data: (json['data'] as List).map((item) {
        // 1. แปลงข้อมูลใน 'product' ให้เป็น Product Object
        final product = Product.fromJson(item['product']);
        
        // 2. เอาจำนวน (quantity) จากด้านนอก (Stock) มาแปะใส่ Product
        return product.copyWith(quantity: item['quantity']);
      }).toList(),
    );
  }
}