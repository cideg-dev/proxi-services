class User {
  final int id;
  final String email;
  final String? name;
  final String? role;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? coverImage;
  final double? latitude;
  final double? longitude;
  final bool? isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.role,
    this.avatarUrl,
    this.phoneNumber,
    this.address,
    this.city,
    this.coverImage,
    this.latitude,
    this.longitude,
    this.isOnline,
    this.lastSeen,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      name: json['name'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      city: json['city'],
      coverImage: json['cover_image'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isOnline: json['is_online'],
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'cover_image': coverImage,
      'latitude': latitude,
      'longitude': longitude,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
