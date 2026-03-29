class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isEmailVerified;
  final List<String> roles;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    required this.isEmailVerified,
    required this.roles,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isEmailVerified: json['isEmailVerified'] ?? false,
      roles: List<String>.from(json['roles'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isEmailVerified': isEmailVerified,
      'roles': roles,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  bool get isAdmin => roles.contains('Admin');
  
  User copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    bool? isEmailVerified,
    List<String>? roles,
  }) {
    return User(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      roles: roles ?? this.roles,
      createdAt: this.createdAt,
    );
  }
}
