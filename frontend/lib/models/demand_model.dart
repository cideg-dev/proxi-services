class Demand {
  final int id;
  final int clientId;
  final int artisanId;
  final List<int>? serviceIds;
  final String? serviceDescription;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Demand({
    required this.id,
    required this.clientId,
    required this.artisanId,
    this.serviceIds,
    this.serviceDescription,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Demand.fromJson(Map<String, dynamic> json) {
    return Demand(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      clientId: json['client_id'] is int ? json['client_id'] : int.tryParse(json['client_id'].toString()) ?? 0,
      artisanId: json['artisan_id'] is int ? json['artisan_id'] : int.tryParse(json['artisan_id'].toString()) ?? 0,
      serviceIds: json['service_ids'] != null 
          ? (json['service_ids'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      serviceDescription: json['service_description'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'artisan_id': artisanId,
      'service_ids': serviceIds,
      'service_description': serviceDescription,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
