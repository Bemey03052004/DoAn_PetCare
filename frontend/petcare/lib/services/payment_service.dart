import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/payment_transaction.dart';
import 'auth_service.dart';

class PaymentService {
  final AuthService _authService;

  PaymentService(this._authService);

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/payment$endpoint');
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

  Future<PaymentTransaction> createPayment(CreatePaymentRequest request) async {
    final response = await _makeRequest('POST', '/create', body: request.toJson());
    
    if (response['success'] == true) {
      return PaymentTransaction.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to create payment');
    }
  }

  Future<List<PaymentTransaction>> getMyPayments() async {
    final response = await _makeRequest('GET', '/my-payments');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((json) => PaymentTransaction.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to get payments');
    }
  }

  Future<PaymentTransaction> updatePaymentStatus(int id, UpdatePaymentStatusRequest request) async {
    final response = await _makeRequest('PUT', '/$id/status', body: request.toJson());
    
    if (response['success'] == true) {
      return PaymentTransaction.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to update payment status');
    }
  }

  Future<List<String>> getPaymentMethods() async {
    final response = await _makeRequest('GET', '/methods');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.cast<String>();
    } else {
      throw Exception(response['message'] ?? 'Failed to get payment methods');
    }
  }

  // Helper methods for common payment scenarios
  Future<PaymentTransaction> createPetSalePayment({
    required int petId,
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    return createPayment(CreatePaymentRequest(
      transactionType: 'PetSale',
      paymentMethod: paymentMethod,
      amount: amount,
      petId: petId,
      description: description ?? 'Payment for pet purchase',
    ));
  }

  Future<PaymentTransaction> createBoardingDepositPayment({
    required int petBoardingRequestId,
    required double depositAmount,
    required String paymentMethod,
    String? description,
  }) async {
    return createPayment(CreatePaymentRequest(
      transactionType: 'BoardingDeposit',
      paymentMethod: paymentMethod,
      amount: depositAmount,
      depositAmount: depositAmount,
      petBoardingRequestId: petBoardingRequestId,
      description: description ?? 'Deposit for pet boarding service',
    ));
  }

  Future<PaymentTransaction> createBoardingPayment({
    required int petBoardingRequestId,
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    return createPayment(CreatePaymentRequest(
      transactionType: 'BoardingPayment',
      paymentMethod: paymentMethod,
      amount: amount,
      petBoardingRequestId: petBoardingRequestId,
      description: description ?? 'Payment for pet boarding service',
    ));
  }
}
