class AdoptionRequestWithTag {
  final int id;
  final int petId;
  final String petName;
  final String? petImageUrl;
  final int userId;
  final String userName;
  final int petOwnerId;
  final String petOwnerName;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Tag information
  final String petTag; // "Cho", "Giữ dùm", "Bán"
  final bool isForSale;
  final bool isForBoarding;
  final double? salePrice;
  final double? boardingPricePerDay;

  AdoptionRequestWithTag({
    required this.id,
    required this.petId,
    required this.petName,
    this.petImageUrl,
    required this.userId,
    required this.userName,
    required this.petOwnerId,
    required this.petOwnerName,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.petTag,
    required this.isForSale,
    required this.isForBoarding,
    this.salePrice,
    this.boardingPricePerDay,
  });

  factory AdoptionRequestWithTag.fromJson(Map<String, dynamic> json) {
    return AdoptionRequestWithTag(
      id: json['id'] as int,
      petId: json['petId'] as int,
      petName: json['petName'] as String,
      petImageUrl: json['petImageUrl'] as String?,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      petOwnerId: json['petOwnerId'] as int,
      petOwnerName: json['petOwnerName'] as String,
      message: json['message'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      petTag: json['petTag'] as String,
      isForSale: json['isForSale'] as bool,
      isForBoarding: json['isForBoarding'] as bool,
      salePrice: json['salePrice'] != null ? (json['salePrice'] as num).toDouble() : null,
      boardingPricePerDay: json['boardingPricePerDay'] != null ? (json['boardingPricePerDay'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'petImageUrl': petImageUrl,
      'userId': userId,
      'userName': userName,
      'petOwnerId': petOwnerId,
      'petOwnerName': petOwnerName,
      'message': message,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'petTag': petTag,
      'isForSale': isForSale,
      'isForBoarding': isForBoarding,
      'salePrice': salePrice,
      'boardingPricePerDay': boardingPricePerDay,
    };
  }
}
