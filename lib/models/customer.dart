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
    this.id = 0, // for create new
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
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      customerNo: json['customer_no']?.toString() ?? '-',
      name: json['name']?.toString() ?? 'ไม่มีชื่อ',
      email: json['email']?.toString() ?? '',
      tel: json['tel']?.toString() ?? '-',
      address: json['address']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      postCode: json['post_code']?.toString() ?? json['postCode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'TH',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_no': customerNo,
      'name': name,
      'email': email,
      'tel': tel,
      'address': address,
      'district': district,
      'province': province,
      'postCode': postCode,
      'country': country,
    };
  }
} 