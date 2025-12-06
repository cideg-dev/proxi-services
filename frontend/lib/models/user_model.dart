class User {
  final int id;
  final String email;
  final String? name;
  final String? role;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? address;
  final String? city;

  User({
    required this.id,
    required this.email,
    this.name,
    this.role,
    this.avatarUrl,
    this.phoneNumber,
    this.address,
    this.city,
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
    };
  }
}
