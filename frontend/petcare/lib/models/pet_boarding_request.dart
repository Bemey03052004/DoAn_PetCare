class PetBoardingRequest {
  final int? id;
  final int petId;
  final String petName;
  final String? petImageUrl;
  final int requesterId;
  final String requesterName;
  final int petOwnerId;
  final String petOwnerName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String? specialInstructions;
  final String? contactPhone;
  final String? contactAddress;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? ownerNotes;
  final String? requesterNotes;

  const PetBoardingRequest({
    this.id,
    required this.petId,
    required this.petName,
    this.petImageUrl,
    required this.requesterId,
    required this.requesterName,
    required this.petOwnerId,
    required this.petOwnerName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.specialInstructions,
    this.contactPhone,
    this.contactAddress,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.ownerNotes,
    this.requesterNotes,
  });

  factory PetBoardingRequest.fromJson(Map<String, dynamic> json) {
    return PetBoardingRequest(
      id: json['id'] as int?,
      petId: json['petId'] as int,
      petName: json['petName'] as String,
      petImageUrl: json['petImageUrl'] as String?,
      requesterId: json['requesterId'] as int,
      requesterName: json['requesterName'] as String,
      petOwnerId: json['petOwnerId'] as int,
      petOwnerName: json['petOwnerName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      specialInstructions: json['specialInstructions'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactAddress: json['contactAddress'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      ownerNotes: json['ownerNotes'] as String?,
      requesterNotes: json['requesterNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'petImageUrl': petImageUrl,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'petOwnerId': petOwnerId,
      'petOwnerName': petOwnerName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'specialInstructions': specialInstructions,
      'contactPhone': contactPhone,
      'contactAddress': contactAddress,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'ownerNotes': ownerNotes,
      'requesterNotes': requesterNotes,
    };
  }
}

class CreateBoardingRequest {
  final int petId;
  final DateTime startDate;
  final DateTime endDate;
  final String? specialInstructions;
  final String? contactPhone;
  final String? contactAddress;

  const CreateBoardingRequest({
    required this.petId,
    required this.startDate,
    required this.endDate,
    this.specialInstructions,
    this.contactPhone,
    this.contactAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'petId': petId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'specialInstructions': specialInstructions,
      'contactPhone': contactPhone,
      'contactAddress': contactAddress,
    };
  }
}

class UpdateBoardingRequest {
  final String? status;
  final String? ownerNotes;
  final String? requesterNotes;

  const UpdateBoardingRequest({
    this.status,
    this.ownerNotes,
    this.requesterNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'ownerNotes': ownerNotes,
      'requesterNotes': requesterNotes,
    };
  }
}
