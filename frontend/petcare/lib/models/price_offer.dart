class PriceOffer {
  final int id;
  final int petId;
  final String petName;
  final String petImageUrl;
  final int offererId;
  final String offererName;
  final int receiverId;
  final String receiverName;
  final double offeredAmount;
  final String? message;
  final String status;
  final double? counterOfferAmount;
  final String? counterOfferMessage;
  final String? counterOfferStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? counterOfferAt;
  final List<PriceOfferHistory> history;

  PriceOffer({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petImageUrl,
    required this.offererId,
    required this.offererName,
    required this.receiverId,
    required this.receiverName,
    required this.offeredAmount,
    this.message,
    required this.status,
    this.counterOfferAmount,
    this.counterOfferMessage,
    this.counterOfferStatus,
    required this.createdAt,
    this.updatedAt,
    this.counterOfferAt,
    required this.history,
  });

  factory PriceOffer.fromJson(Map<String, dynamic> json) {
    return PriceOffer(
      id: json['id'] ?? 0,
      petId: json['petId'] ?? 0,
      petName: json['petName'] ?? '',
      petImageUrl: json['petImageUrl'] ?? '',
      offererId: json['offererId'] ?? 0,
      offererName: json['offererName'] ?? '',
      receiverId: json['receiverId'] ?? 0,
      receiverName: json['receiverName'] ?? '',
      offeredAmount: (json['offeredAmount'] ?? 0).toDouble(),
      message: json['message'],
      status: json['status'] ?? '',
      counterOfferAmount: json['counterOfferAmount']?.toDouble(),
      counterOfferMessage: json['counterOfferMessage'],
      counterOfferStatus: json['counterOfferStatus'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      counterOfferAt: json['counterOfferAt'] != null ? DateTime.parse(json['counterOfferAt']) : null,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((h) => PriceOfferHistory.fromJson(h))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'petImageUrl': petImageUrl,
      'offererId': offererId,
      'offererName': offererName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'offeredAmount': offeredAmount,
      'message': message,
      'status': status,
      'counterOfferAmount': counterOfferAmount,
      'counterOfferMessage': counterOfferMessage,
      'counterOfferStatus': counterOfferStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'counterOfferAt': counterOfferAt?.toIso8601String(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }
}

class PriceOfferHistory {
  final int id;
  final int userId;
  final String userName;
  final String action;
  final double? amount;
  final String? message;
  final DateTime createdAt;

  PriceOfferHistory({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    this.amount,
    this.message,
    required this.createdAt,
  });

  factory PriceOfferHistory.fromJson(Map<String, dynamic> json) {
    return PriceOfferHistory(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      action: json['action'] ?? '',
      amount: json['amount']?.toDouble(),
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'action': action,
      'amount': amount,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
