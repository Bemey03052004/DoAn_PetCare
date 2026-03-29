# PetCare API Documentation - Authentication

## Overview

This document describes the authentication API endpoints for the PetCare application. These endpoints allow users to register accounts, log in, and manage their authentication state.

## Base URL

```
https://[your-domain]/api
```

Replace `[your-domain]` with your actual API domain (e.g., `localhost:7267` for local development).

## Authentication

Most endpoints require JWT authentication. After logging in, include the received token in the `Authorization` header of your requests:

```
Authorization: Bearer [your-jwt-token]
```

## Endpoints

### 1. User Registration

Register a new user account.

- **URL**: `/auth/register`
- **Method**: `POST`
- **Authentication Required**: No

**Request Body**:

```json
{
  "fullName": "User Full Name",
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "confirmPassword": "SecurePassword123!",
  "phone": "0912345678",           // Optional
  "address": "123 Street Address",  // Optional
  "latitude": 10.7758439,          // Optional
  "longitude": 106.7017555         // Optional
}
```

**Field Requirements**:
- `fullName`: Required, maximum 100 characters
- `email`: Required, valid email format, maximum 100 characters, must be unique
- `password`: Required, minimum 6 characters, must contain at least one uppercase letter, one number, and one special character
- `confirmPassword`: Required, must match password
- `phone`: Optional, maximum 20 characters
- `address`: Optional, maximum 255 characters
- `latitude` and `longitude`: Optional, for location-based features

**Success Response**:
- **Code**: `201 Created`
- **Content**:

```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "id": 123,
    "fullName": "User Full Name",
    "email": "user@example.com",
    "phone": "0912345678",
    "address": "123 Street Address",
    "latitude": 10.7758439,
    "longitude": 106.7017555,
    "roles": ["User"],
    "createdAt": "2025-10-15T10:30:45Z"
  }
}
```

**Error Responses**:

- **Code**: `400 Bad Request` - Validation failed
- **Content**:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "FullName: Full name is required",
    "Email: Invalid email format",
    "Password: Password must contain at least one uppercase letter"
  ]
}
```

- **Code**: `409 Conflict` - Email already registered
- **Content**:

```json
{
  "success": false,
  "message": "Email already in use"
}
```

- **Code**: `500 Internal Server Error` - Server error
- **Content**:

```json
{
  "success": false,
  "message": "An error occurred during registration"
}
```

### 2. User Login

Authenticate a user and receive a JWT token.

- **URL**: `/auth/login`
- **Method**: `POST`
- **Authentication Required**: No

**Request Body**:

```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Success Response**:
- **Code**: `200 OK`
- **Content**:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 123,
      "fullName": "User Full Name",
      "email": "user@example.com",
      "phone": "0912345678",
      "address": "123 Street Address",
      "latitude": 10.7758439,
      "longitude": 106.7017555,
      "roles": ["User"],
      "createdAt": "2025-10-15T10:30:45Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiration": "2025-10-15T12:30:45Z"
  }
}
```

**Error Responses**:

- **Code**: `400 Bad Request` - Validation failed
- **Content**:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "Email: Email is required",
    "Password: Password is required"
  ]
}
```

- **Code**: `401 Unauthorized` - Invalid credentials
- **Content**:

```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

- **Code**: `500 Internal Server Error` - Server error
- **Content**:

```json
{
  "success": false,
  "message": "An error occurred during login"
}
```

## Flutter Integration Guide

### Setting Up Flutter Client

1. **Add Required Packages**:

```yaml
dependencies:
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1
  # or riverpod or bloc for state management
```

2. **API Service Class**:

```dart
class AuthService {
  final String baseUrl = 'https://[your-domain]/api';
  final http.Client client = http.Client();
  final FlutterSecureStorage storage = FlutterSecureStorage();

  // User Registration
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    final responseData = jsonDecode(response.body);
    return responseData;
  }

  // User Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);
    
    if (response.statusCode == 200 && responseData['success']) {
      // Store token securely
      await storage.write(
        key: 'auth_token', 
        value: responseData['data']['token']
      );
      
      // Store user info if needed
      await storage.write(
        key: 'user_info', 
        value: jsonEncode(responseData['data']['user'])
      );
    }
    
    return responseData;
  }

  // Get stored token
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // Logout
  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user_info');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

3. **User Registration Screen Example**:

```dart
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone (Optional)'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address (Optional)'),
                ),
                SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading 
                      ? CircularProgressIndicator() 
                      : Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userData = {
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'confirmPassword': _confirmPasswordController.text,
          'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          'address': _addressController.text.isEmpty ? null : _addressController.text,
          // You can add location data if available
        };

        final response = await _authService.register(userData);

        if (response['success']) {
          // Registration successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful! Please login.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // Registration failed
          setState(() {
            _errorMessage = response['message'] ?? 'Registration failed';
            if (response['errors'] != null) {
              _errorMessage = response['errors'].join('\n');
            }
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again later.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
```

4. **Login Screen Example**:

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                    ? CircularProgressIndicator() 
                    : Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await _authService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (response['success']) {
          // Login successful
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Login failed
          setState(() {
            _errorMessage = response['message'] ?? 'Invalid email or password';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again later.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
```

5. **Auth Provider for State Management**:

```dart
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isAuthenticated = await _authService.isLoggedIn();
    if (_isAuthenticated) {
      // Get stored user info
      final userInfoStr = await FlutterSecureStorage().read(key: 'user_info');
      if (userInfoStr != null) {
        _user = jsonDecode(userInfoStr);
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _authService.register(userData);
    return response;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _authService.login(email, password);
    if (response['success']) {
      _isAuthenticated = true;
      _user = response['data']['user'];
      notifyListeners();
    }
    return response;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
```

6. **Main App Setup**:

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isAuthenticated) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegistrationScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
```

## Best Practices

1. **Error Handling**: Always handle API errors gracefully and provide clear feedback to users.
2. **Token Storage**: Use `flutter_secure_storage` or similar secure storage options for storing JWT tokens.
3. **Validation**: Implement client-side validation to match server-side validation rules.
4. **Loading States**: Show loading indicators during API calls to improve user experience.
5. **Expiry Handling**: Check token expiration and implement token refresh logic if needed.
6. **Network Connectivity**: Handle network interruptions gracefully.