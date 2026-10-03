class SaleReceipt {
  final int id;
  final String billNo;
  final Map<String, dynamic> data;

  SaleReceipt._(this.id, this.billNo, this.data);

  factory SaleReceipt.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    final rawId = json['id'] ?? data['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    final rawBill = json['billNo'] ?? json['bill_no'] ?? data['bill_no'];
    if (id == null || id <= 0 || rawBill is! String || rawBill.trim().isEmpty) {
      throw const FormatException('รายการขายไม่มีเลขบิลจากเซิร์ฟเวอร์');
    }
    return SaleReceipt._(id, rawBill, data);
  }
}
