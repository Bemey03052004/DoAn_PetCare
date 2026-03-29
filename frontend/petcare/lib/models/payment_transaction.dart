class PaymentTransaction {
  final int? id;
  final int userId;
  final String userName;
  final String transactionType;
  final String paymentMethod;
  final double amount;
  final double? depositAmount;
  final String status;
  final String? description;
  final String? referenceId;
  final int? petId;
  final String? petName;
  final int? petBoardingRequestId;
  final int? adoptionRequestId;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  const PaymentTransaction({
    this.id,
    required this.userId,
    required this.userName,
    required this.transactionType,
    required this.paymentMethod,
    required this.amount,
    this.depositAmount,
    required this.status,
    this.description,
    this.referenceId,
    this.petId,
    this.petName,
    this.petBoardingRequestId,
    this.adoptionRequestId,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      transactionType: json['transactionType'] as String,
      paymentMethod: json['paymentMethod'] as String,
      amount: (json['amount'] as num).toDouble(),
      depositAmount: json['depositAmount']?.toDouble(),
      status: json['status'] as String,
      description: json['description'] as String?,
      referenceId: json['referenceId'] as String?,
      petId: json['petId'] as int?,
      petName: json['petName'] as String?,
      petBoardingRequestId: json['petBoardingRequestId'] as int?,
      adoptionRequestId: json['adoptionRequestId'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'transactionType': transactionType,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'depositAmount': depositAmount,
      'status': status,
      'description': description,
      'referenceId': referenceId,
      'petId': petId,
      'petName': petName,
      'petBoardingRequestId': petBoardingRequestId,
      'adoptionRequestId': adoptionRequestId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class CreatePaymentRequest {
  final String transactionType;
  final String paymentMethod;
  final double amount;
  final double? depositAmount;
  final String? description;
  final int? petId;
  final int? petBoardingRequestId;
  final int? adoptionRequestId;
  final String? notes;

  const CreatePaymentRequest({
    required this.transactionType,
    required this.paymentMethod,
    required this.amount,
    this.depositAmount,
    this.description,
    this.petId,
    this.petBoardingRequestId,
    this.adoptionRequestId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionType': transactionType,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'depositAmount': depositAmount,
      'description': description,
      'petId': petId,
      'petBoardingRequestId': petBoardingRequestId,
      'adoptionRequestId': adoptionRequestId,
      'notes': notes,
    };
  }
}

class UpdatePaymentStatusRequest {
  final String status;
  final String? referenceId;
  final String? notes;

  const UpdatePaymentStatusRequest({
    required this.status,
    this.referenceId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'referenceId': referenceId,
      'notes': notes,
    };
  }
}
