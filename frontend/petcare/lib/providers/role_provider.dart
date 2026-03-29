import 'package:flutter/foundation.dart';
import '../models/role.dart';
import '../models/user.dart';
import '../services/role_service.dart';

class RoleProvider with ChangeNotifier {
  final RoleService _roleService;
  
  List<Role> _roles = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  RoleProvider(this._roleService);
  
  List<Role> get roles => _roles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadAllRoles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _roles = await _roleService.getAllRoles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  Future<Role?> getRoleById(int id) async {
    try {
      return await _roleService.getRoleById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<Role?> createRole(String name, String? description) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final createdRole = await _roleService.createRole(name, description);
      _roles.add(createdRole);
      _isLoading = false;
      notifyListeners();
      return createdRole;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<Role?> updateRole(int id, String name, String? description) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updatedRole = await _roleService.updateRole(id, name, description);
      
      // Update the role in the list
      final index = _roles.indexWhere((role) => role.id == id);
      if (index != -1) {
        _roles[index] = updatedRole;
      }
      
      _isLoading = false;
      notifyListeners();
      return updatedRole;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> deleteRole(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _roleService.deleteRole(id);
      
      if (result) {
        // Remove the role from the list
        _roles.removeWhere((role) => role.id == id);
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
  
  Future<List<User>?> getUsersInRole(int id) async {
    try {
      return await _roleService.getUsersInRole(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
