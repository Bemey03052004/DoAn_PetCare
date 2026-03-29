import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/boarding_request.dart';
import 'auth_service.dart';

class BoardingService {
  final AuthService _authService;

  BoardingService(this._authService);

  Future<BoardingRequest> createBoardingRequest({
    required int petId,
    required int customerId,
    required DateTime startDate,
    required DateTime endDate,
    double? customPricePerDay,
    String? specialInstructions,
    String? contactPhone,
    String? contactAddress,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/boarding/request');
    
    final body = jsonEncode({
      'petId': petId,
      'customerId': customerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'customPricePerDay': customPricePerDay,
      'specialInstructions': specialInstructions,
      'contactPhone': contactPhone,
      'contactAddress': contactAddress,
    });

    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return BoardingRequest.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to create boarding request');
  }

  Future<List<BoardingRequest>> getMyBoardingRequests() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/boarding/my');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((json) => BoardingRequest.fromJson(json)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to get boarding requests');
  }

  Future<BoardingRequest?> getBoardingRequestById(int id) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/boarding/$id');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return BoardingRequest.fromJson(responseBody['data']);
    }
    return null;
  }

  Future<BoardingRequest> updateBoardingStatus({
    required int boardingRequestId,
    required String status,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/boarding/$boardingRequestId/status');
    
    final body = jsonEncode({
      'status': status,
    });

    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return BoardingRequest.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update boarding status');
  }

  Future<List<BoardingRequest>> getReceivedBoardingRequests() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/boarding/received-requests');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List list = responseBody['data'] as List;
      return list.map((e) => BoardingRequest.fromJson(e)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to load received boarding requests');
  }

  Future<Map<String, dynamic>> createBoardingPayment({
    required int boardingRequestId,
    required String paymentMethod,
    String? transactionId,
    String? notes,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/boarding/payment');
    
    final body = jsonEncode({
      'boardingRequestId': boardingRequestId,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'notes': notes,
    });

    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return responseBody['data'] as Map<String, dynamic>;
    }
    throw Exception(responseBody['message'] ?? 'Failed to create boarding payment');
  }

  Future<BoardingRequest> confirmPaymentSuccess({
    required int boardingRequestId,
    String? paymentReference,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/boarding/payment-success');
    
    final body = jsonEncode({
      'boardingRequestId': boardingRequestId,
      'paymentReference': paymentReference,
    });

    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return BoardingRequest.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to confirm payment success');
  }
}
