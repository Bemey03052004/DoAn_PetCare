class BoardingRequest {
  final int id;
  final int petId;
  final String petName;
  final String petImageUrl;
  final int ownerId;
  final String ownerName;
  final int customerId;
  final String customerName;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePerDay;
  final double totalAmount;
  final String? specialInstructions;
  final String? contactPhone;
  final String? contactAddress;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BoardingRequest({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petImageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.customerId,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.pricePerDay,
    required this.totalAmount,
    this.specialInstructions,
    this.contactPhone,
    this.contactAddress,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory BoardingRequest.fromJson(Map<String, dynamic> json) {
    return BoardingRequest(
      id: json['id'] ?? 0,
      petId: json['petId'] ?? 0,
      petName: json['petName'] ?? '',
      petImageUrl: json['petImageUrl'] ?? '',
      ownerId: json['ownerId'] ?? 0,
      ownerName: json['ownerName'] ?? '',
      customerId: json['customerId'] ?? 0,
      customerName: json['customerName'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      specialInstructions: json['specialInstructions'],
      contactPhone: json['contactPhone'],
      contactAddress: json['contactAddress'],
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'petImageUrl': petImageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'customerId': customerId,
      'customerName': customerName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'pricePerDay': pricePerDay,
      'totalAmount': totalAmount,
      'specialInstructions': specialInstructions,
      'contactPhone': contactPhone,
      'contactAddress': contactAddress,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  int get totalDays => endDate.difference(startDate).inDays;
}
