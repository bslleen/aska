import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? bio;
  final String userType; // 'student', 'teacher', or 'admin'
  final DateTime createdAt;
  final String? authToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.bio,
    required this.userType,
    required this.createdAt,
    this.authToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      bio: json['bio'],
      userType: json['user_type'] ?? 'student', // Default to student for backward compatibility
      createdAt: DateTime.parse(json['created_at']),
      authToken: json['auth_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'bio': bio,
      'user_type': userType,
      'created_at': createdAt.toIso8601String(),
      'auth_token': authToken,
    };
  }
}

class AuthProvider extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8001';
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _user!.authToken != null;
  bool get isAdmin => _user != null && _user!.userType == 'admin';

  AuthProvider() {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      final authToken = prefs.getString('auth_token');
      
      print('Loading persisted user - User JSON: ${userJson != null}');
      print('Loading persisted user - Auth Token: ${authToken != null}');
      
      if (userJson != null && authToken != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        
        // CRITICAL FIX: Check if cached data is stale for admin users
        final username = userMap['username']?.toString() ?? '';
        final userType = userMap['user_type']?.toString() ?? '';
        
        // For user "lea", if cached data shows student role but should be admin, clear cache
        if (username == 'lea' && (userType == null || userType == 'student')) {
          print('Found stale cached data for user "lea". Clearing cache to fetch fresh admin role...');
          // Clear stale cached data
          await _clearPersistedUser();
          clearUser();
          print('Cleared stale cached session data - user "lea" needs fresh login');
          return;
        }
        
        // For other users, proceed normally (they might legitimately be students)
        
        _user = User.fromJson({...userMap, 'auth_token': authToken});
        print('Loaded user: ${_user?.username}, Role: ${_user?.userType}, Token: ${_user?.authToken?.substring(0, 20)}...');
        notifyListeners();
      } else {
        print('No persisted session found');
      }
    } catch (e) {
      print('Error loading persisted user: $e');
      // Silently fail if no persisted session
      clearUser();
    }
  }

  Future<void> _persistUser() async {
    if (_user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(_user!.toJson()));
    await prefs.setString('auth_token', _user!.authToken ?? '');
  }

  Future<void> _clearPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('auth_token');
  }

  // ------------------------------
  // Register new user
  // ------------------------------
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? bio,
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'full_name': fullName,
          'bio': bio,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Extract auth_token from response and add it to user data
        final authToken = data['auth_token'] as String?;
        final userMap = Map<String, dynamic>.from(data['user'] as Map);
        final userData = {...userMap, 'auth_token': authToken};
        _user = User.fromJson(userData);
        await _persistUser();
        notifyListeners();
        setLoading(false);
        return true;
      } else {
        setError(data['error'] ?? 'Registration failed');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Network error: $e');
      setLoading(false);
      return false;
    }
  }

  // ------------------------------
  // Login user
  // ------------------------------
  Future<bool> login({
    String? username,
    String? email,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Extract auth_token from response and add it to user data
        final authToken = data['auth_token'] as String?;
        final userMap = Map<String, dynamic>.from(data['user'] as Map);
        final userData = {...userMap, 'auth_token': authToken};
        _user = User.fromJson(userData);
        await _persistUser();
        notifyListeners();
        setLoading(false);
        return true;
      } else {
        setError(data['error'] ?? 'Login failed');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Network error: $e');
      setLoading(false);
      return false;
    }
  }

  // ------------------------------
  // Logout user
  // ------------------------------
  Future<bool> logout() async {
    setLoading(true);
    clearError();

    try {
      final token = _user?.authToken;
      final response = await http.post(
        Uri.parse('$baseUrl/logout.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      // Always clear local session data regardless of server response
      // This ensures user can logout even if server is unreachable
      _user = null;
      await _clearPersistedUser();
      notifyListeners();

      if (response.statusCode == 200 && data['success'] == true) {
        setLoading(false);
        return true;
      } else {
        // Still return true since we cleared local data
        // But log the error for debugging
        print('Logout server error: ${data['error'] ?? 'Unknown error'}');
        setLoading(false);
        return true;
      }
    } catch (e) {
      // Network error - still clear local session
      print('Logout network error: $e');
      _user = null;
      await _clearPersistedUser();
      notifyListeners();
      setLoading(false);
      return true; // Return true since local logout succeeded
    }
  }

  // ------------------------------
  // Get current user info
  // ------------------------------
  Future<bool> getCurrentUser() async {
    setLoading(true);
    clearError();

    try {
      final token = _user?.authToken;
      final response = await http.get(
        Uri.parse('$baseUrl/get_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userMap = data['user'] as Map<String, dynamic>;
        final userData = {...userMap, 'auth_token': token};
        _user = User.fromJson(userData);
        await _persistUser();
        notifyListeners();
        setLoading(false);
        return true;
      } else {
        _user = null;
        await _clearPersistedUser();
        notifyListeners();
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Network error: $e');
      setLoading(false);
      return false;
    }
  }

  // ------------------------------
  // Update user profile
  // ------------------------------
  Future<bool> updateUser({
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? userType,
    String? currentPassword,
    String? newPassword,
  }) async {
    setLoading(true);
    clearError();

    try {
      final token = _user?.authToken;
      if (token == null) {
        setError('User not authenticated');
        setLoading(false);
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/update_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          if (fullName != null) 'full_name': fullName,
          if (bio != null) 'bio': bio,
          if (userType != null) 'user_type': userType,
          if (currentPassword != null) 'current_password': currentPassword,
          if (newPassword != null) 'new_password': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userMap = data['user'] as Map<String, dynamic>;
        final userData = {...userMap, 'auth_token': token};
        _user = User.fromJson(userData);
        await _persistUser();
        notifyListeners();
        setLoading(false);
        return true;
      } else {
        setError(data['error'] ?? 'Update failed');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('Network error: $e');
      setLoading(false);
      return false;
    }
  }

  // ------------------------------
  // Helper methods
  // ------------------------------
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
