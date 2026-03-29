import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/pet_boarding_request.dart';
import 'auth_service.dart';

class PetBoardingService {
  final AuthService _authService;

  PetBoardingService(this._authService);

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/petboarding$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Request failed');
    }
  }

  Future<PetBoardingRequest> createBoardingRequest(CreateBoardingRequest request) async {
    final response = await _makeRequest('POST', '/request', body: request.toJson());
    
    if (response['success'] == true) {
      return PetBoardingRequest.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to create boarding request');
    }
  }

  Future<List<PetBoardingRequest>> getMyBoardingRequests() async {
    final response = await _makeRequest('GET', '/my-requests');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => PetBoardingRequest.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to get boarding requests');
    }
  }

  Future<List<PetBoardingRequest>> getReceivedBoardingRequests() async {
    final response = await _makeRequest('GET', '/received-requests');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => PetBoardingRequest.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to get received boarding requests');
    }
  }

  Future<PetBoardingRequest> updateBoardingRequest(int id, UpdateBoardingRequest request) async {
    final response = await _makeRequest('PUT', '/$id', body: request.toJson());
    
    if (response['success'] == true) {
      return PetBoardingRequest.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to update boarding request');
    }
  }
}
