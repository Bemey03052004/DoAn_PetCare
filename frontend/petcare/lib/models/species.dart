class Species {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  Species({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}


