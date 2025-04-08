import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _errorMessage = '';

  bool get isLoggedIn => _isLoggedIn;
  String get errorMessage => _errorMessage;

  // Define the base URL for the API (Heroku or localhost)
  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com'; // Heroku URL for Android
    } else if (Platform.isIOS) {
      return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com'; // Heroku URL for iOS
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:8080'; // Use localhost for testing
    }
    return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com'; // Default for other cases
  }

  // Login method using phone number and password
  Future<bool> login(String phoneNumber, String password) async {
    final url = Uri.parse('${getBaseUrl()}/api/providers/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber, // Sending phone number instead of email
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid phone number or password';
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = 'Something went wrong. Please try again later.';
      notifyListeners();
      return false;
    }
  }

  // Logout method
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
