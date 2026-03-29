import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/sale_request.dart';
import 'auth_service.dart';

class SaleService {
  final AuthService _authService;

  SaleService(this._authService);

  Future<SaleRequest> createSaleRequest({
    required int petId,
    required int buyerId,
    required double amount,
    String? message,
    String paymentMethod = 'Cash',
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/sale/request');
    
    final body = jsonEncode({
      'petId': petId,
      'buyerId': buyerId,
      'amount': amount,
      'message': message,
      'paymentMethod': paymentMethod,
    });

    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return SaleRequest.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to create sale request');
  }

  Future<List<SaleRequest>> getMySaleRequests() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/sale/my');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List list = responseBody['data'] as List;
      return list.map((e) => SaleRequest.fromJson(e)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to load sale requests');
  }

  Future<SaleRequest> updateSaleStatus({
    required int saleRequestId,
    required String status,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/sale/$saleRequestId/status');
    
    final body = jsonEncode({
      'status': status,
    });

    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return SaleRequest.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update sale status');
  }

  Future<SaleRequest?> getSaleRequestForPet(int petId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/sale/pet/$petId');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return SaleRequest.fromJson(responseBody['data']);
    } else if (res.statusCode == 404) {
      return null; // No sale request found for this pet
    }
    throw Exception(responseBody['message'] ?? 'Failed to load sale request for pet');
  }

  Future<List<SaleRequest>> getReceivedSaleRequests() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/sale/received-requests');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List list = responseBody['data'] as List;
      return list.map((e) => SaleRequest.fromJson(e)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to load received sale requests');
  }

  Future<Map<String, dynamic>> createPayment({
    required int saleRequestId,
    required String paymentMethod,
    String? transactionId,
    String? notes,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/sale/payment');
    
    final body = jsonEncode({
      'saleRequestId': saleRequestId,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'notes': notes,
    });

    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return responseBody['data'] as Map<String, dynamic>;
    }
    throw Exception(responseBody['message'] ?? 'Failed to create payment');
  }

  Future<Map<String, dynamic>> updatePaymentStatus({
    required int paymentId,
    required String status,
    String? referenceId,
    String? notes,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/payment/$paymentId/status');
    
    final body = jsonEncode({
      'status': status,
      'referenceId': referenceId,
      'notes': notes,
    });

    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return responseBody['data'] as Map<String, dynamic>;
    }
    throw Exception(responseBody['message'] ?? 'Failed to update payment status');
  }
}
