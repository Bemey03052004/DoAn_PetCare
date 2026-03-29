import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService;
  
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  UserProvider(this._userService);
  
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadAllUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _users = await _userService.getAllUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  Future<User?> getUserById(int id) async {
    try {
      return await _userService.getUserById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<User?> getProfile() async {
    try {
      return await _userService.getProfile();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<User?> updateProfile(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedUser = await _userService.updateProfile(userData);
      
      // Update the user in the list if it exists
      final index = _users.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      _isLoading = false;
      notifyListeners();
      return updatedUser;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<User?> updateUser(int id, Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedUser = await _userService.updateUser(id, userData);
      
      // Update the user in the list if it exists
      final index = _users.indexWhere((user) => user.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      _isLoading = false;
      notifyListeners();
      return updatedUser;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> deleteUser(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _userService.deleteUser(id);
      
      if (result) {
        // Remove the user from the list
        _users.removeWhere((user) => user.id == id);
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<List<String>?> getUserRoles(int id) async {
    try {
      return await _userService.getUserRoles(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> addRoleToUser(int id, String roleName) async {
    try {
      final result = await _userService.addRoleToUser(id, roleName);
      
      // Update the user in the list if it exists
      if (result) {
        final index = _users.indexWhere((user) => user.id == id);
        if (index != -1) {
          final updatedUser = await getUserById(id);
          if (updatedUser != null) {
            _users[index] = updatedUser;
            notifyListeners();
          }
        }
      }
      
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> removeRoleFromUser(int id, String roleName) async {
    try {
      final result = await _userService.removeRoleFromUser(id, roleName);
      
      // Update the user in the list if it exists
      if (result) {
        final index = _users.indexWhere((user) => user.id == id);
        if (index != -1) {
          final updatedUser = await getUserById(id);
          if (updatedUser != null) {
            _users[index] = updatedUser;
            notifyListeners();
          }
        }
      }
      
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
