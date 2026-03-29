class VaccinationSchedule {
  final int id;
  final int petId;
  final String vaccineName;
  final DateTime scheduledDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const VaccinationSchedule({
    required this.id,
    required this.petId,
    required this.vaccineName,
    required this.scheduledDate,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
  });

  factory VaccinationSchedule.fromJson(Map<String, dynamic> json) {
    return VaccinationSchedule(
      id: json['id'] as int,
      petId: json['petId'] as int,
      vaccineName: json['vaccineName'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate']),
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'vaccineName': vaccineName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
