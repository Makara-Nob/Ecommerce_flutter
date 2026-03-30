import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/auth/auth_response.dart';
import '../models/auth/register_request.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserData? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _token;

  UserData? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  // Try to auto-login with stored token
  Future<bool> tryAutoLogin() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) return false;

      // Fetch fresh profile data
      final response = await _authService.getProfile();
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        _isAuthenticated = true;
        _token = token;
        
        // Update stored user data
        await _storageService.saveUser(response.data!);
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(username, password);

      if (response.success && response.data != null && response.data!.token.isNotEmpty) {
        // Save token first
        final token = response.data!.token;
        _token = token;
        await _storageService.saveToken(token);

        // Fetch full profile to ensure we have all fields (including profileUrl)
        final profileResponse = await _authService.getProfile();
        
        if (profileResponse.success && profileResponse.data != null) {
           _currentUser = profileResponse.data;
           // Save complete user data
           await _storageService.saveUser(_currentUser!);
        } else {
           // Fallback to login response data if getProfile fails
           _currentUser = response.data!.user;
           await _storageService.saveUser(_currentUser!);
        }

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty 
            ? response.message 
            : (response.data?.token.isEmpty ?? true ? 'Login failed: No token received' : 'Login failed');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register(String username, String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );

      final response = await _authService.register(request);

      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty 
            ? response.message 
            : 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during registration: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.verifyOtp(email, otp);

      if (response.success && response.data != null && response.data!.token.isNotEmpty) {
        final token = response.data!.token;
        _token = token;
        await _storageService.saveToken(token);

        // Fetch full profile
        final profileResponse = await _authService.getProfile();
        
        if (profileResponse.success && profileResponse.data != null) {
           _currentUser = profileResponse.data;
           await _storageService.saveUser(_currentUser!);
        } else {
           _currentUser = response.data!.user;
           await _storageService.saveUser(_currentUser!);
        }

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty 
            ? response.message 
            : 'Verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during OTP verification: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.resendOtp(email);

      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty 
            ? response.message 
            : 'Failed to resend OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _token = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update Profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.updateProfile(
        fullName: fullName,
        phone: phone,
        email: email,
      );

      if (response.success && response.data != null) {
        _currentUser = response.data; // Update current user in memory
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upload and Update Profile Image
  Future<bool> uploadProfileImage(File file) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload File
      final uploadResponse = await _authService.uploadProfileImage(file);
      
      if (!uploadResponse.success || uploadResponse.data == null) {
        _errorMessage = uploadResponse.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final imageUrl = uploadResponse.data!;

      // 2. Update User Profile with new URL
      final updateResponse = await _authService.updateProfileWithImage(imageUrl);
      
      if (updateResponse.success && updateResponse.data != null) {
        _currentUser = updateResponse.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
         _errorMessage = updateResponse.message;
         _isLoading = false;
         notifyListeners();
         return false;
      }

    } catch (e) {
      _errorMessage = 'Image upload failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}