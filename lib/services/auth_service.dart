import 'dart:convert';
import 'package:dictionary_app/models/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // For development - flag to use mock or real API
  static const bool useMock = true; // Set to false when API is ready

  static Future<AuthResponse> register(RegisterRequest request) async {
    if (useMock) {
      return await _mockRegister(request);
    }
    
    // Real API implementation will go here when endpoints exist
    throw AuthException('Register endpoint not available yet', 404);
  }

  static Future<AuthResponse> login(LoginRequest request) async {
    if (useMock) {
      return await _mockLogin(request);
    }
    
    // Real API implementation will go here when endpoints exist
    throw AuthException('Login endpoint not available yet', 404);
  }

  // ========== MOCK IMPLEMENTATION ==========
  
  static Future<AuthResponse> _mockRegister(RegisterRequest request) async {
    print('🔧 Using MOCK registration');
    
    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));
    
    // Create mock response matching your API documentation
    final mockResponse = {
      "message": "User created successfully",
      "token": "mock_jwt_${DateTime.now().millisecondsSinceEpoch}",
      "user": {
        "id": DateTime.now().millisecondsSinceEpoch,
        "email": request.email,
        "name": request.name,
      }
    };
    
    final user = User.fromJson(mockResponse['user'] as Map<String, dynamic>);
    await _saveAuthData(mockResponse['token'] as String, user);
    
    return AuthResponse(
      success: true,
      message: mockResponse['message'] as String,
      user: user,
      token: mockResponse['token'] as String,
    );
  }

  static Future<AuthResponse> _mockLogin(LoginRequest request) async {
    print('🔧 Using MOCK login');
    
    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));
    
    // Check if user exists in mock storage
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString(_userKey);
    
    if (storedUser != null) {
      final userMap = json.decode(storedUser) as Map<String, dynamic>;
      final storedEmail = userMap['email'] as String?;
      
      // For mock, accept any password but check email
      if (storedEmail == request.email) {
        final user = User.fromJson(userMap);
        final token = await getToken();
        
        return AuthResponse(
          success: true,
          message: "Login successful",
          user: user,
          token: token,
        );
      }
    }
    
    // If no user exists, auto-register them (for mock only)
    print('⚠️ No user found, auto-registering for mock...');
    return await _mockRegister(RegisterRequest(
      name: request.email.split('@').first,
      email: request.email,
      password: request.password,
    ));
  }

  // ========== SHARED METHODS ==========
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    print('👋 User logged out');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = json.decode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        print('Error parsing stored user: $e');
        return null;
      }
    }
    
    return null;
  }

  static Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // Store user with token
    final userWithToken = user.copyWith(token: token);
    await prefs.setString(_userKey, json.encode(userWithToken.toJson()));
    
    print('💾 Auth data saved for: ${user.email}');
  }

  // Method to clear all auth data (for testing)
  static Future<void> clearAllAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    print('🧹 All auth data cleared');
  }
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, [this.statusCode]);

  @override
  String toString() => 'AuthException: $message${statusCode != null ? ' ($statusCode)' : ''}';
}

// Helper function for auth error messages in Khmer
String getAuthErrorMessage(dynamic error) {
  if (error is AuthException) {
    switch (error.statusCode) {
      case 400:
        return 'ព័ត៌មានមិនត្រឹមត្រូវ';
      case 401:
        return 'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ';
      case 403:
        return 'គណនីនេះត្រូវបានហាមឃាត់';
      case 404:
        return 'គណនីមិនត្រូវបានរកឃើញ';
      case 409:
        return 'អ៊ីមែលនេះបានប្រើប្រាស់រួចហើយ';
      case 422:
        return 'ទិន្នន័យមិនត្រឹមត្រូវ';
      case 500:
        return 'មានបញ្ហានៅក្នុងម៉ាស៊ីនបម្រើ';
      default:
        if (error.message.contains('not available yet')) {
          return 'មុខងារចុះឈ្មោះនៅមិនទាន់អាចប្រើបានទេ។ កំពុងប្រើទិន្នន័យម៉ាក់សម្រាប់ការអភិវឌ្ឍ។';
        }
        return 'ការផ្ទៀងផ្ទាត់បានបរាជ័យ: ${error.message}';
    }
  }
  return 'កំហុសមិនស្គាល់: $error';
}