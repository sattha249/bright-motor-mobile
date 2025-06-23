class TruckInfo {
  final int id;
  final int? truckId;
  final String? username;
  final String? email;
  final String? fullName;
  final String? tel;
  final String? role;

  TruckInfo(this.id, this.truckId, this.username, this.email, this.fullName, this.tel,
      this.role);

  factory TruckInfo.fromJson(Map<String, dynamic> json) {
    return TruckInfo(
      json['id'] as int,
      json['truck_id'] as int?,
      json['username'] as String?,
      json['email'] as String?,
      json['fullname'] as String?,
      json['tel'] as String?,
      json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'truck_id': truckId,
      'username': username,
      'email': email,
      'fullName': fullName,
      'tel': tel,
      'role': role,
    };
  }

}