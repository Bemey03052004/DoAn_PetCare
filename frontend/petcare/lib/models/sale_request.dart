class SaleRequest {
  final int id;
  final int petId;
  final String petName;
  final String petImageUrl;
  final int sellerId;
  final String sellerName;
  final int buyerId;
  final String buyerName;
  final double amount;
  final String? message;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SaleRequest({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petImageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.amount,
    this.message,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory SaleRequest.fromJson(Map<String, dynamic> json) {
    return SaleRequest(
      id: json['id'] ?? 0,
      petId: json['petId'] ?? 0,
      petName: json['petName'] ?? '',
      petImageUrl: json['petImageUrl'] ?? '',
      sellerId: json['sellerId'] ?? 0,
      sellerName: json['sellerName'] ?? '',
      buyerId: json['buyerId'] ?? 0,
      buyerName: json['buyerName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      message: json['message'],
      paymentMethod: json['paymentMethod'] ?? '',
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
      'sellerId': sellerId,
      'sellerName': sellerName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'amount': amount,
      'message': message,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
