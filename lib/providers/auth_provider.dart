import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _errorMessage = '';
  String _phoneNumber = '';
  String _token = '';

  bool get isLoggedIn => _isLoggedIn;
  String get errorMessage => _errorMessage;
  String get phoneNumber => _phoneNumber;
  String get token => _token;

  // Define the base URL for the API
  String getBaseUrl() {
    return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com';
  }

  // Load the login state from SharedPreferences
  Future<void> loadLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _phoneNumber = prefs.getString('phoneNumber') ?? '';
      _token = prefs.getString('token') ?? '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading login state: $e');
      // Continue with default values if there's an error
    }
  }

  // Save login state to SharedPreferences
  Future<void> saveLoginState({
    required bool isLoggedIn, 
    String phoneNumber = '', 
    String token = ''
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);
      
      if (phoneNumber.isNotEmpty) {
        await prefs.setString('phoneNumber', phoneNumber);
        _phoneNumber = phoneNumber;
      }
      
      if (token.isNotEmpty) {
        await prefs.setString('token', token);
        _token = token;
      }
      
      _isLoggedIn = isLoggedIn;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving login state: $e');
      // Handle the error appropriately
    }
  }

  // Format phone number for API consistency while preserving the leading zero
  String _formatPhoneNumber(String phone) {
    // Remove any spaces from the phone number
    String cleanPhone = phone.replaceAll(' ', '');
    
    // If the number starts with +233, convert to format with leading 0
    if (cleanPhone.startsWith('+233')) {
      return '0${cleanPhone.substring(4)}';
    } 
    // If the number starts with 233, convert to format with leading 0
    else if (cleanPhone.startsWith('233')) {
      return '0${cleanPhone.substring(3)}';
    } 
    // If the number doesn't start with 0, add it
    else if (!cleanPhone.startsWith('0')) {
      return '0$cleanPhone';
    }
    
    // Already in the correct format with leading 0
    return cleanPhone;
  }

  // Login method using phone number and password
  Future<bool> login(String phoneNumber, String password) async {
    final url = Uri.parse('${getBaseUrl()}/api/providers/login');
    
    try {
      // Format the phone number to maintain the leading 0 format
      String formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // Add timeout to detect network issues faster
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': formattedPhone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      // Handle success response (200 OK)
      if (response.statusCode == 200) {
        try {
          // Try to parse as JSON first
          final responseData = json.decode(response.body);
          await saveLoginState(
            isLoggedIn: true,
            phoneNumber: formattedPhone, // Save the formatted phone number
            token: responseData['token'] ?? '',
          );
          return true;
        } catch (parseError) {
          // If response is not JSON but status is 200, consider it a success
          await saveLoginState(
            isLoggedIn: true,
            phoneNumber: formattedPhone, // Save the formatted phone number
            token: '',  // No token available
          );
          return true;
        }
      } 
      // Handle 400 Bad Request response (invalid credentials)
      else if (response.statusCode == 400) {
        try {
          // Try to parse as JSON first
          final responseData = json.decode(response.body);
          _errorMessage = responseData['message'] ?? 'Invalid phone number or password';
        } catch (parseError) {
          // If not JSON, use the plain text response
          _errorMessage = response.body.trim();
          if (_errorMessage.isEmpty) {
            _errorMessage = 'Invalid phone number or password';
          }
        }
        notifyListeners();
        return false;
      } 
      // Handle other error responses
      else {
        try {
          final responseData = json.decode(response.body);
          _errorMessage = responseData['message'] ?? 'Server error (${response.statusCode})';
        } catch (parseError) {
          _errorMessage = response.body.trim();
          if (_errorMessage.isEmpty) {
            _errorMessage = 'Server error (${response.statusCode})';
          }
        }
        notifyListeners();
        return false;
      }
    } on SocketException {
      _errorMessage = 'Network connection error. Please check your internet connection.';
      notifyListeners();
      return false;
    } on TimeoutException {
      _errorMessage = 'Connection timed out. Server might be down or slow.';
      notifyListeners();
      return false;
    } on http.ClientException catch (e) {
      _errorMessage = 'HTTP client error: ${e.message}';
      notifyListeners();
      return false;
    } catch (error) {
      debugPrint('Login error: $error');
      _errorMessage = 'Connection error. Please try again later.';
      notifyListeners();
      return false;
    }
  }

  // Reset password using phone number and new password
  Future<bool> resetPassword(String phoneNumber, String newPassword) async {
    // Format the phone number to maintain the leading 0 format
    String formattedPhone = _formatPhoneNumber(phoneNumber);
    
    final url = Uri.parse('${getBaseUrl()}/api/providers/reset-password?phoneNumber=$formattedPhone');
    
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _errorMessage = '';
        notifyListeners();
        return true;
      } else {
        try {
          final responseData = json.decode(response.body);
          _errorMessage = responseData['message'] ?? 'Failed to reset password';
        } catch (parseError) {
          _errorMessage = response.body.trim();
          if (_errorMessage.isEmpty) {
            _errorMessage = 'Failed to reset password';
          }
        }
        notifyListeners();
        return false;
      }
    } catch (error) {
      debugPrint('Reset password error: $error');
      _errorMessage = 'Connection error. Please try again later.';
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep the phone number for convenience but clear the token
      String savedPhone = _phoneNumber;
      await prefs.remove('isLoggedIn');
      await prefs.remove('token');
      // Optionally keep the phone number for convenience
      _isLoggedIn = false;
      _phoneNumber = savedPhone; // Keep phone number for next login
      _token = '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Handle any errors during logout
    }
  }
}