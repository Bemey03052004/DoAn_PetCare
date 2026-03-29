import 'package:flutter/foundation.dart';
import '../models/create_pet_request.dart';
import '../models/pet.dart';
import '../models/adoption_request_with_tag.dart';
import '../services/pet_service.dart';

class PetProvider with ChangeNotifier {
  final PetService _petService;

  PetProvider(this._petService);

  List<Pet> _publicPets = [];
  List<Pet> _myPets = [];
  List<AdoptionRequestWithTag> _myAdoptionRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Pet> get publicPets => _publicPets;
  List<Pet> get myPets => _myPets;
  List<AdoptionRequestWithTag> get myAdoptionRequests => _myAdoptionRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPublicPets({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _publicPets = await _petService.getPublicPets(
        species: species,
        minAgeMonths: minAgeMonths,
        maxAgeMonths: maxAgeMonths,
        keyword: keyword,
        lat: lat,
        lng: lng,
        maxDistanceKm: maxDistanceKm,
        filter: filter,
        sortBy: sortBy,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<Pet?> loadPetDetail(int id) async {
    try {
      final pet = await _petService.getPetById(id);
      return pet;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Pet?> createPet(CreatePetRequest req) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pet = await _petService.createPet(req.toJson());
      _isLoading = false;
      // Nếu public ngay, thêm vào danh sách public hiện tại
      if (pet.isPublic) {
        _publicPets = [pet, ..._publicPets];
      }
      notifyListeners();
      return pet;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Pet?> publishPet(int id, bool isPublic) async {
    try {
      final pet = await _petService.publishPet(id, isPublic);
      // cập nhật danh sách public tùy trạng thái
      _publicPets = _publicPets.where((p) => p.id != pet.id).toList();
      if (pet.isPublic) {
        _publicPets = [pet, ..._publicPets];
      }
      // cập nhật danh sách của tôi
      _myPets = _myPets.map((p) => p.id == pet.id ? pet : p).toList();
      notifyListeners();
      return pet;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Pet?> showPetAgain(int id) async {
    try {
      final pet = await _petService.showPetAgain(id);
      // cập nhật danh sách public
      _publicPets = _publicPets.where((p) => p.id != pet.id).toList();
      if (pet.isPublic) {
        _publicPets = [pet, ..._publicPets];
      }
      // cập nhật danh sách của tôi
      _myPets = _myPets.map((p) => p.id == pet.id ? pet : p).toList();
      notifyListeners();
      return pet;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMyPets(int ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _myPets = await _petService.getMyPets(ownerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createAdoptionRequest(int petId, {String? message}) async {
    try {
      await _petService.createAdoptionRequest(petId, message: message);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> loadAdoptionRequests(int petId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _petService.getAdoptionRequests(petId);
      _isLoading = false;
      notifyListeners();
      return list;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> acceptAdoption(int adoptionId) async {
    try {
      await _petService.acceptAdoption(adoptionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> declineAdoption(int adoptionId) async {
    try {
      await _petService.declineAdoption(adoptionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reopenAdoption(int adoptionId) async {
    try {
      await _petService.reopenAdoption(adoptionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyAdoptionRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _myAdoptionRequests = await _petService.getMyAdoptionRequestsWithTags();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String? getMyAdoptionStatusForPet(int petId) {
    try {
      final match = _myAdoptionRequests.firstWhere(
        (e) => e.petId == petId,
        orElse: () => AdoptionRequestWithTag(
          id: 0,
          petId: 0,
          petName: '',
          userId: 0,
          userName: '',
          petOwnerId: 0,
          petOwnerName: '',
          status: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          petTag: '',
          isForSale: false,
          isForBoarding: false,
        ),
      );
      return match.status.isEmpty ? null : match.status;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updatePet(Pet pet) async {
    try {
      final success = await _petService.updatePet(pet);
      if (success) {
        // Update the pet in the list if it exists
        final index = _publicPets.indexWhere((p) => p.id == pet.id);
        if (index != -1) {
          _publicPets[index] = pet;
        }
        
        final myPetIndex = _myPets.indexWhere((p) => p.id == pet.id);
        if (myPetIndex != -1) {
          _myPets[myPetIndex] = pet;
        }
        
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}


