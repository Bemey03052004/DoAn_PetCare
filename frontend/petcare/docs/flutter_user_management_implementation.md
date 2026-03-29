# PetCare Flutter Implementation - User Management

This guide shows how to implement the user management features in your Flutter application, building on the authentication system already documented.

## Project Setup

Ensure you've already implemented the authentication system from the `flutter_auth_implementation.md` guide.

### Add Required Models

First, add or update the necessary models for user management:

#### Update User Model

Update the `lib/models/user.dart` file to include more functionality:

```dart
class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> roles;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    required this.roles,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      roles: List<String>.from(json['roles'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'roles': roles,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  bool get isAdmin => roles.contains('Admin');
  
  User copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? roles,
  }) {
    return User(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      roles: roles ?? this.roles,
      createdAt: this.createdAt,
    );
  }
}
```

#### Create Role Model

Create a new file `lib/models/role.dart`:

```dart
class Role {
  final int id;
  final String name;
  final String? description;

  Role({
    required this.id,
    required this.name,
    this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
```

## Services Implementation

### User Service

Create `lib/services/user_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_care_app/config/api_config.dart';
import 'package:pet_care_app/models/user.dart';
import 'package:pet_care_app/services/auth_service.dart';

class UserService {
  final AuthService _authService;

  UserService(this._authService);

  Future<List<User>> getAllUsers() async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          final List<dynamic> userData = responseData['data'];
          return userData.map((json) => User.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving users: $e');
    }
  }

  Future<User> getUserById(int id) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$id'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving user: $e');
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$id'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Future<List<String>> getUserRoles(int id) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$id/roles'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return List<String>.from(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load user roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving user roles: $e');
    }
  }

  Future<bool> addRoleToUser(int id, String roleName) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$id/roles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roleName': roleName}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to add role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding role: $e');
    }
  }

  Future<bool> removeRoleFromUser(int id, String roleName) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/users/$id/roles/$roleName'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to remove role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing role: $e');
    }
  }
}
```

### Role Service

Create `lib/services/role_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_care_app/config/api_config.dart';
import 'package:pet_care_app/models/role.dart';
import 'package:pet_care_app/models/user.dart';
import 'package:pet_care_app/services/auth_service.dart';

class RoleService {
  final AuthService _authService;

  RoleService(this._authService);

  Future<List<Role>> getAllRoles() async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          final List<dynamic> roleData = responseData['data'];
          return roleData.map((json) => Role.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving roles: $e');
    }
  }

  Future<Role> getRoleById(int id) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return Role.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving role: $e');
    }
  }

  Future<Role> createRole(String name, String? description) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return Role.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to create role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating role: $e');
    }
  }

  Future<Role> updateRole(int id, String name, String? description) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return Role.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to update role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating role: $e');
    }
  }

  Future<bool> deleteRole(int id) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to delete role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting role: $e');
    }
  }

  Future<List<User>> getUsersInRole(int id) async {
    try {
      final client = await _authService.getAuthenticatedClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id/users'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          final List<dynamic> userData = responseData['data'];
          return userData.map((json) => User.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load users in role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving users in role: $e');
    }
  }
}
```

## State Management Implementation

### User Provider

Create `lib/providers/user_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:pet_care_app/models/user.dart';
import 'package:pet_care_app/services/user_service.dart';

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
```

### Role Provider

Create `lib/providers/role_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:pet_care_app/models/role.dart';
import 'package:pet_care_app/models/user.dart';
import 'package:pet_care_app/services/role_service.dart';

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
```

## UI Implementation

### Profile Screen

Create `lib/screens/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/models/user.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _populateForm();
  }
  
  void _populateForm() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
    }
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        try {
          final userData = {
            'fullName': _fullNameController.text,
            'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
            'address': _addressController.text.isEmpty ? null : _addressController.text,
          };
          
          final updatedUser = await userProvider.updateUser(user.id, userData);
          
          if (updatedUser != null) {
            // Update the auth provider with the updated user
            authProvider.updateCurrentUser(updatedUser);
            
            setState(() {
              _isEditing = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User avatar
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            
            // User information
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isEditing,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Non-editable information
            Card(
              child: ListTile(
                title: const Text('Email'),
                subtitle: Text(user.email),
                leading: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: ListTile(
                title: const Text('Roles'),
                subtitle: Text(user.roles.join(', ')),
                leading: const Icon(Icons.security),
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: ListTile(
                title: const Text('Member Since'),
                subtitle: Text(
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
                leading: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 24),
            
            if (user.isAdmin)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin/users');
                },
                child: const Text('Manage Users'),
              ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () async {
                await authProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### User List Screen (Admin Only)

Create `lib/screens/admin/user_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/models/user.dart';
import 'package:pet_care_app/providers/user_provider.dart';
import 'package:pet_care_app/providers/auth_provider.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    // Load users when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadAllUsers();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = Provider.of<AuthProvider>(context).user;
    
    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: userProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : userProvider.errorMessage != null
              ? Center(child: Text('Error: ${userProvider.errorMessage}'))
              : ListView.builder(
                  itemCount: userProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = userProvider.users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user.fullName.substring(0, 1)),
                        ),
                        title: Text(user.fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Text(
                              'Roles: ${user.roles.join(", ")}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showUserActions(context, user);
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(userId: user.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Reload users
          userProvider.loadAllUsers();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  void _showUserActions(BuildContext context, User user) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    
    // Don't allow the current user to delete themselves
    final isSelf = currentUser?.id == user.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserDetailScreen(userId: user.id),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Manage Roles'),
                onTap: () {
                  Navigator.pop(context);
                  _showManageRolesDialog(context, user);
                },
              ),
              if (!isSelf) // Don't allow deleting self
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete User', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await _confirmDeletion(context, user);
                    if (confirmed) {
                      await userProvider.deleteUser(user.id);
                      userProvider.loadAllUsers(); // Reload the list
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  Future<bool> _confirmDeletion(BuildContext context, User user) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
  
  void _showManageRolesDialog(BuildContext context, User user) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Manage Roles for ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Current Roles:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: user.roles.map((role) {
                  return Chip(
                    label: Text(role),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () async {
                      Navigator.pop(context);
                      await userProvider.removeRoleFromUser(user.id, role);
                      userProvider.loadAllUsers(); // Reload the list
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Add Role:'),
              const SizedBox(height: 8),
              FutureBuilder<List<String>?>(
                future: _getAllAvailableRoles(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Text('Error loading roles');
                  }
                  
                  final availableRoles = snapshot.data!
                      .where((role) => !user.roles.contains(role))
                      .toList();
                  
                  if (availableRoles.isEmpty) {
                    return const Text('No available roles to add');
                  }
                  
                  return Wrap(
                    spacing: 8,
                    children: availableRoles.map((role) {
                      return ActionChip(
                        label: Text(role),
                        onPressed: () async {
                          Navigator.pop(context);
                          await userProvider.addRoleToUser(user.id, role);
                          userProvider.loadAllUsers(); // Reload the list
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  Future<List<String>?> _getAllAvailableRoles(BuildContext context) async {
    try {
      // In a real app, you would fetch this from the role service
      // For this example, we'll hardcode a few roles
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      return ['User', 'Admin', 'Moderator', 'PetOwner', 'Veterinarian'];
    } catch (e) {
      return null;
    }
  }
}

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<User?> _userFuture;
  
  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }
  
  Future<User?> _loadUser() async {
    return await Provider.of<UserProvider>(context, listen: false)
        .getUserById(widget.userId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (snapshot.data == null) {
            return const Center(child: Text('User not found'));
          }
          
          final user = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile header
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // User details
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailItem('Phone', user.phone ?? 'Not provided'),
                _buildDetailItem('Address', user.address ?? 'Not provided'),
                _buildDetailItem(
                  'Member Since',
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
                
                const SizedBox(height: 24),
                
                // Roles section
                const Text(
                  'Roles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: user.roles.map((role) {
                    return Chip(label: Text(role));
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
```

### Register Services and Providers

Update `lib/main.dart` to include the new services and providers:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/services/auth_service.dart';
import 'package:pet_care_app/services/user_service.dart';
import 'package:pet_care_app/services/role_service.dart';
import 'package:pet_care_app/providers/auth_provider.dart';
import 'package:pet_care_app/providers/user_provider.dart';
import 'package:pet_care_app/providers/role_provider.dart';
import 'package:pet_care_app/screens/splash_screen.dart';
import 'package:pet_care_app/screens/login_screen.dart';
import 'package:pet_care_app/screens/registration_screen.dart';
import 'package:pet_care_app/screens/home_screen.dart';
import 'package:pet_care_app/screens/profile_screen.dart';
import 'package:pet_care_app/screens/admin/user_list_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create services
    final authService = AuthService();
    final userService = UserService(authService);
    final roleService = RoleService(authService);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(userService),
          update: (_, auth, previous) => previous ?? UserProvider(userService),
        ),
        ChangeNotifierProvider(create: (_) => RoleProvider(roleService)),
      ],
      child: MaterialApp(
        title: 'PetCare',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/admin/users': (context) => const UserListScreen(),
        },
      ),
    );
  }
}
```

### Update AuthProvider

Update `lib/providers/auth_provider.dart` to add a method for updating the current user:

```dart
class AuthProvider with ChangeNotifier {
  // Add this method to the existing AuthProvider class
  
  void updateCurrentUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
```

## Update Home Screen

Update `lib/screens/home_screen.dart` to include a profile button:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_care_app/providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
          if (user?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.of(context).pushNamed('/admin/users');
              },
            ),
        ],
      },
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to PetCare!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (user != null) 
                Text('Hello, ${user.fullName}'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Navigate to pets feature
                },
                child: const Text('View My Pets'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Testing

Test your implementation by:

1. Logging in with different user roles
2. Viewing and updating your profile
3. If you're an admin, try managing users and roles
4. Test the permission restrictions by trying to access admin features as a regular user

This implementation provides a comprehensive user management system for your Flutter application, including:

1. User profile management
2. Role-based access control
3. Admin interfaces for managing users and roles
4. Clean separation of concerns with providers and services

You can expand on this base by adding more features like:
- User search and filtering
- Pagination for large user lists
- More detailed user analytics
- Password change functionality