class Customer {
  final int id;
  final String customerNo;
  final String name;
  final String email;
  final String tel;
  final String address;
  final String district;
  final String province;
  final String postCode;
  final String country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.customerNo,
    required this.name,
    required this.email,
    required this.tel,
    required this.address,
    required this.district,
    required this.province,
    required this.postCode,
    required this.country,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      customerNo: json['customer_no'],
      name: json['name'],
      email: json['email'] ?? '',
      tel: json['tel'],
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? '',
      postCode: json['post_code'] ?? '',
      country: json['country'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
} 