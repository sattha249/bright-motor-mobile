class TruckInfo {
  final int id;
  final String? username;
  final String? email;
  final String? fullName;
  final String? tel;
  final String? role;

  TruckInfo(this.id, this.username, this.email, this.fullName, this.tel,
      this.role);

  factory TruckInfo.fromJson(Map<String, dynamic> json) {
    return TruckInfo(
      json['id'] as int,
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
      'username': username,
      'email': email,
      'fullName': fullName,
      'tel': tel,
      'role': role,
    };
  }

}