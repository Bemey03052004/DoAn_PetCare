import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/price_offer.dart';
import 'auth_service.dart';

class PriceOfferService {
  final AuthService _authService;

  PriceOfferService(this._authService);

  Future<PriceOffer> createPriceOffer({
    required int petId,
    required double offeredAmount,
    String? message,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/priceoffer');
    
    final body = jsonEncode({
      'petId': petId,
      'offeredAmount': offeredAmount,
      'message': message,
    });

    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return PriceOffer.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to create price offer');
  }

  Future<List<PriceOffer>> getPriceOffersForPet(int petId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/priceoffer/pet/$petId');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List list = responseBody['data'] as List;
      return list.map((e) => PriceOffer.fromJson(e)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to load price offers');
  }

  Future<List<PriceOffer>> getMyOffers() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/priceoffer/my-offers');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List list = responseBody['data'] as List;
      return list.map((e) => PriceOffer.fromJson(e)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to load my offers');
  }

  Future<PriceOffer?> getMyOfferForPet(int petId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/priceoffer/my-offer/pet/$petId');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return PriceOffer.fromJson(responseBody['data']);
    } else if (res.statusCode == 404) {
      return null; // No offer found for this pet
    }
    throw Exception(responseBody['message'] ?? 'Failed to load my offer for pet');
  }

  Future<List<PriceOffer>> getReceivedOffers() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/priceoffer/received-offers');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List list = responseBody['data'] as List;
      return list.map((e) => PriceOffer.fromJson(e)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to load received offers');
  }

  Future<PriceOffer> makeCounterOffer({
    required int priceOfferId,
    required double counterOfferAmount,
    String? counterOfferMessage,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/priceoffer/$priceOfferId/counter-offer');
    
    final body = jsonEncode({
      'counterOfferAmount': counterOfferAmount,
      'counterOfferMessage': counterOfferMessage,
    });

    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return PriceOffer.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to make counter offer');
  }

  Future<PriceOffer> updateOfferStatus({
    required int priceOfferId,
    required String status,
  }) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/priceoffer/$priceOfferId/status');
    
    final body = jsonEncode({
      'status': status,
    });

    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return PriceOffer.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update offer status');
  }
}
