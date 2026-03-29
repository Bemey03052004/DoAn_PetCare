class AdoptionRequest {
  final int id;
  final int petId;
  final int userId;
  final String status;
  final String? message;

  AdoptionRequest({
    required this.id,
    required this.petId,
    required this.userId,
    required this.status,
    this.message,
  });

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) {
    return AdoptionRequest(
      id: json['id'] as int,
      petId: json['petId'] as int,
      userId: json['userId'] as int,
      status: json['status'] as String,
      message: json['message'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'userId': userId,
      'status': status,
      'message': message,
    };
  }
}
