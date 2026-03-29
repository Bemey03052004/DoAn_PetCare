import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/pet.dart';
import '../models/adoption_request_with_tag.dart';
import 'auth_service.dart';

class PetService {
  final AuthService _authService;

  PetService(this._authService);

  Future<List<Pet>> getPublicPets({
    String? species, 
    int? minAgeMonths, 
    int? maxAgeMonths, 
    String? keyword, 
    double? lat, 
    double? lng, 
    double? maxDistanceKm,
    String? filter,
    String? sortBy,
  }) async {
    final params = <String, String>{};
    if (species != null && species.isNotEmpty) params['species'] = species;
    if (minAgeMonths != null) params['minAgeMonths'] = minAgeMonths.toString();
    if (maxAgeMonths != null) params['maxAgeMonths'] = maxAgeMonths.toString();
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (lat != null && lng != null && maxDistanceKm != null) {
      params['lat'] = lat.toString();
      params['lng'] = lng.toString();
      params['maxDistanceKm'] = maxDistanceKm.toString();
    }
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
    if (sortBy != null && sortBy.isNotEmpty) params['sortBy'] = sortBy;

    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/public').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      final List list = body['data'] as List;
      return list.map((e) => Pet.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Failed to load public pets');
  }

  Future<Pet> getPetById(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$id');
    final res = await http.get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return Pet.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to load pet');
  }

  Future<List<Pet>> getMyPets(int ownerId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/owner/$ownerId');
    final res = await http.get(uri, headers: headers);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      final List list = body['data'] as List;
      return list.map((e) => Pet.fromJson(e)).toList();
    }
    throw Exception(body['message'] ?? 'Failed to load my pets');
  }

  Future<Pet> createPet(Map<String, dynamic> dto) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets');
    final res = await http.post(uri, headers: headers, body: jsonEncode(dto));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
      return Pet.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to create pet');
  }

  Future<Pet> publishPet(int id, bool isPublic) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$id/publish');
    final res = await http.put(uri, headers: headers, body: jsonEncode({'isPublic': isPublic}));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return Pet.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to update publish status');
  }

  Future<Pet> showPetAgain(int id) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$id/show-again');
    final res = await http.put(uri, headers: headers);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return Pet.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to show pet again');
  }

  Future<void> createAdoptionRequest(int petId, {String? message}) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$petId/adoptions');
    final res = await http.post(uri, headers: headers, body: jsonEncode({'message': message}));
    if (res.statusCode == 201) return;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to create adoption request');
  }

  Future<List<Map<String, dynamic>>> getAdoptionRequests(int petId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$petId/adoptions');
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return <Map<String, dynamic>>[];
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'] as List;
          return list.cast<Map<String, dynamic>>();
        }
        // Trả về rỗng nếu không có data
        return <Map<String, dynamic>>[];
      } catch (e) {
        // Nếu body không phải JSON hợp lệ, trả về rỗng để tránh crash UI
        return <Map<String, dynamic>>[];
      }
    }
    // Không phải 200: cố parse message để báo lỗi, nếu không thì generic
    try {
      final body = res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to load adoption requests: ${res.statusCode}');
    } catch (_) {
      throw Exception('Failed to load adoption requests: ${res.statusCode}');
    }
  }

  Future<void> acceptAdoption(int adoptionId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/adoptions/$adoptionId/accept');
    final res = await http.put(uri, headers: headers);
    if (res.statusCode == 200) return;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to accept');
  }

  Future<void> declineAdoption(int adoptionId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/adoptions/$adoptionId/decline');
    final res = await http.put(uri, headers: headers);
    if (res.statusCode == 200) return;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to decline');
  }

  Future<void> reopenAdoption(int adoptionId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/adoptions/$adoptionId/reopen');
    final res = await http.put(uri, headers: headers);
    if (res.statusCode == 200) return;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to reopen');
  }

  Future<List<Map<String, dynamic>>> getMyAdoptionRequests() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/adoption/my');
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return <Map<String, dynamic>>[];
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'] as List;
          return list.cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }
    try {
      final body = res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to load my adoption requests: ${res.statusCode}');
    } catch (_) {
      throw Exception('Failed to load my adoption requests: ${res.statusCode}');
    }
  }

  Future<List<AdoptionRequestWithTag>> getMyAdoptionRequestsWithTags() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/adoption/my');
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return <AdoptionRequestWithTag>[];
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'] as List;
          return list.map((e) => AdoptionRequestWithTag.fromJson(e)).toList();
        }
        return <AdoptionRequestWithTag>[];
      } catch (_) {
        return <AdoptionRequestWithTag>[];
      }
    }
    try {
      final body = res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to load my adoption requests: ${res.statusCode}');
    } catch (_) {
      throw Exception('Failed to load my adoption requests: ${res.statusCode}');
    }
  }

  Future<bool> updatePet(Pet pet) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/${pet.id}');
    final body = jsonEncode(pet.toJson());
    
    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return true;
    }
    throw Exception(responseBody['message'] ?? 'Failed to update pet');
  }
}


