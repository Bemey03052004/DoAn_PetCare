import 'pet_profile.dart';
import 'user.dart';
import 'adoptionRequest.dart';
import 'vaccination_schedule.dart';

class Pet {
  final int? id;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final int ageMonths;
  final String? imageUrl;
  final String? description;
  final bool isAdopted;
  final bool isPublic;
  final bool isHidden; // Pet is temporarily hidden when boarding request is pending
  final bool isCurrentlyBoarded; // Pet is currently being boarded (InProgress status)
  final int? currentBoardingCustomerId; // ID of the customer who is currently boarding the pet
  
  // Pet selling fields
  final bool isForSale;
  final double? price;
  final String? saleDescription;

  // Pet boarding fields
  final bool isForBoarding;
  final double? boardingPricePerDay;
  final DateTime? boardingStartDate;
  final DateTime? boardingEndDate;
  final String? boardingDescription;

  final int ownerId;
  final PetProfile? profile;
  final User? owner;
  final DateTime? createdAt;
  final AdoptionRequest? adoptionRequest;
  final List<AdoptionRequest>? adoptionRequests;
  final List<VaccinationSchedule>? vaccinationSchedules;
  const Pet({
    this.id,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    required this.ageMonths,
    this.imageUrl,
    this.description,
    this.isAdopted = false,
    this.isPublic = false,
    this.isHidden = false,
    this.isCurrentlyBoarded = false,
    this.currentBoardingCustomerId,
    this.isForSale = false,
    this.price,
    this.saleDescription,
    this.isForBoarding = false,
    this.boardingPricePerDay,
    this.boardingStartDate,
    this.boardingEndDate,
    this.boardingDescription,
    required this.ownerId,
    this.profile,
    this.owner,
    this.createdAt,
    this.adoptionRequest,
    this.adoptionRequests,
    this.vaccinationSchedules,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as int?,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      gender: json['gender'] as String?,
      ageMonths: (json['ageMonths'] ?? 0) as int,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      isAdopted: (json['isAdopted'] ?? false) as bool,
      isPublic: (json['isPublic'] ?? false) as bool,
      isHidden: (json['isHidden'] ?? false) as bool,
      isCurrentlyBoarded: (json['isCurrentlyBoarded'] ?? false) as bool,
      currentBoardingCustomerId: json['currentBoardingCustomerId'] as int?,
      isForSale: (json['isForSale'] ?? false) as bool,
      price: json['price']?.toDouble(),
      saleDescription: json['saleDescription'] as String?,
      isForBoarding: (json['isForBoarding'] ?? false) as bool,
      boardingPricePerDay: json['boardingPricePerDay']?.toDouble(),
      boardingStartDate: json['boardingStartDate'] != null ? DateTime.parse(json['boardingStartDate']) : null,
      boardingEndDate: json['boardingEndDate'] != null ? DateTime.parse(json['boardingEndDate']) : null,
      boardingDescription: json['boardingDescription'] as String?,
      ownerId: (json['ownerId'] ?? 0) as int,
      profile: json['profile'] != null ? PetProfile.fromJson(json['profile'] as Map<String, dynamic>) : null,
      owner: json['owner'] != null ? User.fromJson(json['owner'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      adoptionRequest: json['adoptionRequest'] != null ? AdoptionRequest.fromJson(json['adoptionRequest'] as Map<String, dynamic>) : null,
      adoptionRequests: json['adoptionRequests'] != null 
          ? (json['adoptionRequests'] as List).map((e) => AdoptionRequest.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      vaccinationSchedules: json['vaccinationSchedules'] != null 
          ? (json['vaccinationSchedules'] as List).map((e) => VaccinationSchedule.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'ageMonths': ageMonths,
      'imageUrl': imageUrl,
      'description': description,
      'isAdopted': isAdopted,
      'isPublic': isPublic,
      'isHidden': isHidden,
      'isForSale': isForSale,
      'price': price,
      'saleDescription': saleDescription,
      'isForBoarding': isForBoarding,
      'boardingPricePerDay': boardingPricePerDay,
      'boardingStartDate': boardingStartDate?.toIso8601String(),
      'boardingEndDate': boardingEndDate?.toIso8601String(),
      'boardingDescription': boardingDescription,
      'ownerId': ownerId,
      'profile': profile?.toJson(),
      'owner': owner?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'adoptionRequest': adoptionRequest?.toJson(),
      'adoptionRequests': adoptionRequests?.map((e) => e.toJson()).toList(),
      'vaccinationSchedules': vaccinationSchedules?.map((e) => e.toJson()).toList(),
    };
  }
}


