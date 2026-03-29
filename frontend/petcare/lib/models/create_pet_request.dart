class CreatePetRequest {
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final int ageMonths;
  final String? imageUrl;
  final String? description;
  final int ownerId;
  final bool isPublic;
  
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

  final String? personality;
  final String? favoriteFood;
  final String? hobbies;
  final String? story;
  final String? socialImage;
  final List<DateTime>? vaccinationDates;

  const CreatePetRequest({
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    required this.ageMonths,
    this.imageUrl,
    this.description,
    required this.ownerId,
    this.isPublic = false,
    this.isForSale = false,
    this.price,
    this.saleDescription,
    this.isForBoarding = false,
    this.boardingPricePerDay,
    this.boardingStartDate,
    this.boardingEndDate,
    this.boardingDescription,
    this.personality,
    this.favoriteFood,
    this.hobbies,
    this.story,
    this.socialImage,
    this.vaccinationDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'ageMonths': ageMonths,
      'imageUrl': imageUrl,
      'description': description,
      'ownerId': ownerId,
      'isPublic': isPublic,
      'isForSale': isForSale,
      'price': price,
      'saleDescription': saleDescription,
      'isForBoarding': isForBoarding,
      'boardingPricePerDay': boardingPricePerDay,
      'boardingStartDate': boardingStartDate?.toIso8601String(),
      'boardingEndDate': boardingEndDate?.toIso8601String(),
      'boardingDescription': boardingDescription,
      'personality': personality,
      'favoriteFood': favoriteFood,
      'hobbies': hobbies,
      'story': story,
      'socialImage': socialImage,
      'vaccinationDates': vaccinationDates?.map((e) => e.toIso8601String()).toList(),
    };
  }
}


