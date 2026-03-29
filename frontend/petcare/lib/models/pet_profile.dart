class PetProfile {
  final int? id;
  final int? petId;
  final String? personality;
  final String? favoriteFood;
  final String? hobbies;
  final String? story;
  final String? socialImage;

  const PetProfile({
    this.id,
    this.petId,
    this.personality,
    this.favoriteFood,
    this.hobbies,
    this.story,
    this.socialImage,
  });

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      id: json['id'] as int?,
      petId: json['petId'] as int?,
      personality: json['personality'] as String?,
      favoriteFood: json['favoriteFood'] as String?,
      hobbies: json['hobbies'] as String?,
      story: json['story'] as String?,
      socialImage: json['socialImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'personality': personality,
      'favoriteFood': favoriteFood,
      'hobbies': hobbies,
      'story': story,
      'socialImage': socialImage,
    };
  }
}


