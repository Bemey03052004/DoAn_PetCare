import 'dart:convert';

class UpdatePetDto {
  final String? name;
  final String? species;
  final String? breed;
  final int? ageMonths;
  final String? gender;
  final String? description;
  final String? imageUrl;
  final double? price;
  final bool? isPublic;
  final bool? isAdopted;
  final bool? isHidden;

  UpdatePetDto({
    this.name,
    this.species,
    this.breed,
    this.ageMonths,
    this.gender,
    this.description,
    this.imageUrl,
    this.price,
    this.isPublic,
    this.isAdopted,
    this.isHidden,
  });

  factory UpdatePetDto.fromJson(Map<String, dynamic> json) {
    return UpdatePetDto(
      name: json['name'],
      species: json['species'],
      breed: json['breed'],
      ageMonths: json['ageMonths'],
      gender: json['gender'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      price: json['price']?.toDouble(),
      isPublic: json['isPublic'],
      isAdopted: json['isAdopted'],
      isHidden: json['isHidden'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'ageMonths': ageMonths,
      'gender': gender,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'isPublic': isPublic,
      'isAdopted': isAdopted,
      'isHidden': isHidden,
    };
  }
}

class TransactionDto {
  final int id;
  final int userId;
  final String userName;
  final double amount;
  final String type;
  final String status;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TransactionDto({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    return TransactionDto(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

class UpdateTransactionStatusDto {
  final String status;

  UpdateTransactionStatusDto({required this.status});

  factory UpdateTransactionStatusDto.fromJson(Map<String, dynamic> json) {
    return UpdateTransactionStatusDto(status: json['status'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}

class DashboardData {
  final int totalPets;
  final int totalUsers;
  final double totalRevenue;
  final double successRate;
  final List<PetDto> recentPets;
  final List<TransactionDto> recentTransactions;

  DashboardData({
    required this.totalPets,
    required this.totalUsers,
    required this.totalRevenue,
    required this.successRate,
    required this.recentPets,
    required this.recentTransactions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalPets: json['totalPets'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      successRate: (json['successRate'] ?? 0).toDouble(),
      recentPets: (json['recentPets'] as List<dynamic>?)
          ?.map((p) => PetDto.fromJson(p))
          .toList() ?? [],
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
          ?.map((t) => TransactionDto.fromJson(t))
          .toList() ?? [],
    );
  }
}

class PetDto {
  final int id;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final int ageMonths;
  final int age;
  final String? imageUrl;
  final String? description;
  final bool isAdopted;
  final bool isPublic;
  final bool isHidden;
  final double? price;
  final String? saleDescription;
  final bool isForSale;
  final bool isForBoarding;
  final double? boardingPricePerDay;
  final DateTime? boardingStartDate;
  final DateTime? boardingEndDate;
  final String? boardingDescription;
  final int ownerId;
  final String? ownerName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PetDto({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    required this.ageMonths,
    required this.age,
    this.imageUrl,
    this.description,
    required this.isAdopted,
    required this.isPublic,
    required this.isHidden,
    this.price,
    this.saleDescription,
    required this.isForSale,
    required this.isForBoarding,
    this.boardingPricePerDay,
    this.boardingStartDate,
    this.boardingEndDate,
    this.boardingDescription,
    required this.ownerId,
    this.ownerName,
    required this.createdAt,
    this.updatedAt,
  });

  factory PetDto.fromJson(Map<String, dynamic> json) {
    return PetDto(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      species: json['species'] ?? 'Dog',
      breed: json['breed'],
      gender: json['gender'],
      ageMonths: json['ageMonths'] ?? 0,
      age: json['age'] ?? 0,
      imageUrl: json['imageUrl'],
      description: json['description'],
      isAdopted: json['isAdopted'] ?? false,
      isPublic: json['isPublic'] ?? false,
      isHidden: json['isHidden'] ?? false,
      price: json['price']?.toDouble(),
      saleDescription: json['saleDescription'],
      isForSale: json['isForSale'] ?? false,
      isForBoarding: json['isForBoarding'] ?? false,
      boardingPricePerDay: json['boardingPricePerDay']?.toDouble(),
      boardingStartDate: json['boardingStartDate'] != null 
          ? DateTime.parse(json['boardingStartDate']) 
          : null,
      boardingEndDate: json['boardingEndDate'] != null 
          ? DateTime.parse(json['boardingEndDate']) 
          : null,
      boardingDescription: json['boardingDescription'],
      ownerId: json['ownerId'] ?? 0,
      ownerName: json['ownerName'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

class UserDto {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> roles;

  UserDto({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
    this.updatedAt,
    required this.roles,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isActive: json['isActive'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      roles: (json['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [],
    );
  }
}

class BoardingRequestDto {
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
  final int? chatRoomId;

  BoardingRequestDto({
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
    this.chatRoomId,
  });

  factory BoardingRequestDto.fromJson(Map<String, dynamic> json) {
    return BoardingRequestDto(
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
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      chatRoomId: json['chatRoomId'],
    );
  }
}

class AdoptionRequestDto {
  final int id;
  final int petId;
  final String petName;
  final String petImageUrl;
  final int userId;
  final String userName;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdoptionRequestDto({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petImageUrl,
    required this.userId,
    required this.userName,
    required this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory AdoptionRequestDto.fromJson(Map<String, dynamic> json) {
    return AdoptionRequestDto(
      id: json['id'] ?? 0,
      petId: json['petId'] ?? 0,
      petName: json['petName'] ?? '',
      petImageUrl: json['petImageUrl'] ?? '',
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

class SystemStatsDto {
  final int totalUsers;
  final int activeUsers;
  final int totalPets;
  final int publicPets;
  final int adoptedPets;
  final int totalTransactions;
  final int completedTransactions;
  final double totalRevenue;
  final double successRate;

  SystemStatsDto({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPets,
    required this.publicPets,
    required this.adoptedPets,
    required this.totalTransactions,
    required this.completedTransactions,
    required this.totalRevenue,
    required this.successRate,
  });

  factory SystemStatsDto.fromJson(Map<String, dynamic> json) {
    return SystemStatsDto(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalPets: json['totalPets'] ?? 0,
      publicPets: json['publicPets'] ?? 0,
      adoptedPets: json['adoptedPets'] ?? 0,
      totalTransactions: json['totalTransactions'] ?? 0,
      completedTransactions: json['completedTransactions'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      successRate: (json['successRate'] ?? 0).toDouble(),
    );
  }
}

class RecentActivitiesDto {
  final List<PetDto> recentPets;
  final List<TransactionDto> recentTransactions;
  final List<BoardingRequestDto> recentBoardingRequests;
  final List<AdoptionRequestDto> recentAdoptionRequests;

  RecentActivitiesDto({
    required this.recentPets,
    required this.recentTransactions,
    required this.recentBoardingRequests,
    required this.recentAdoptionRequests,
  });

  factory RecentActivitiesDto.fromJson(Map<String, dynamic> json) {
    return RecentActivitiesDto(
      recentPets: (json['recentPets'] as List<dynamic>?)
          ?.map((p) => PetDto.fromJson(p))
          .toList() ?? [],
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
          ?.map((t) => TransactionDto.fromJson(t))
          .toList() ?? [],
      recentBoardingRequests: (json['recentBoardingRequests'] as List<dynamic>?)
          ?.map((r) => BoardingRequestDto.fromJson(r))
          .toList() ?? [],
      recentAdoptionRequests: (json['recentAdoptionRequests'] as List<dynamic>?)
          ?.map((r) => AdoptionRequestDto.fromJson(r))
          .toList() ?? [],
    );
  }
}