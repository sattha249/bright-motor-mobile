class PreOrder {
  final int id;
  final String billNo;
  final String status; // Pending, etc.
  final String totalSoldPrice;
  final String isCredit;
  final DateTime? createdAt;
  final POCustomer customer;
  final List<PreOrderItem> items; // สำหรับหน้า Detail

  PreOrder({
    required this.id,
    required this.billNo,
    required this.status,
    required this.totalSoldPrice,
    required this.isCredit,
    required this.createdAt,
    required this.customer,
    this.items = const [],
  });

  factory PreOrder.fromJson(Map<String, dynamic> json) {
    return PreOrder(
      id: json['id'] ?? 0,
      billNo: json['bill_no'] ?? '-',
      status: json['status'] ?? '-',
      totalSoldPrice: json['total_sold_price'] ?? '0.00',
      isCredit: json['is_credit'] ?? 'cash',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      customer: POCustomer.fromJson(json['customer'] ?? {}),
      items: json['items'] != null 
          ? (json['items'] as List).map((x) => PreOrderItem.fromJson(x)).toList() 
          : [],
    );
  }
}

class POCustomer {
  final String name;
  final String tel;

  POCustomer({required this.name, required this.tel});

  factory POCustomer.fromJson(Map<String, dynamic> json) {
    return POCustomer(
      name: json['name'] ?? 'ไม่ระบุชื่อ',
      tel: json['tel'] ?? '-',
    );
  }
}

// Model ย่อยสำหรับรายการสินค้าในใบสั่งซื้อ (เผื่อไว้สำหรับหน้า Detail)
class PreOrderItem {
  final int id;
  final int quantity;
  final String price;
  final String total;
  final String productName;

  PreOrderItem({
    required this.id,
    required this.quantity,
    required this.price,
    required this.total,
    required this.productName,
  });

  factory PreOrderItem.fromJson(Map<String, dynamic> json) {
    // ปรับแก้ตามโครงสร้างจริงของ Detail API (สมมติว่า product อยู่ใน object 'product')
    final product = json['product'] ?? {};
    return PreOrderItem(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: json['sold_price'] ?? '0.00',
      total: json['total_price'] ?? '0.00', // หรือคำนวณเอง
      productName: product['description'] ?? 'สินค้า',
    );
  }
}