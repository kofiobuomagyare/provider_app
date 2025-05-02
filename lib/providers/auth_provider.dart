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
    if (Platform.isAndroid || Platform.isIOS) {
      return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com';
    }
    return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com';
  }

  // Load the login state from SharedPreferences
  Future<void> loadLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _phoneNumber = prefs.getString('phoneNumber') ?? '';
    _token = prefs.getString('token') ?? '';
    notifyListeners();
  }

  // Save login state to SharedPreferences
  Future<void> saveLoginState({
    required bool isLoggedIn, 
    String phoneNumber = '', 
    String token = ''
  }) async {
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
  }

  // Login method using phone number and password
  Future<bool> login(String phoneNumber, String password) async {
    final url = Uri.parse('${getBaseUrl()}/api/providers/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        await saveLoginState(
          isLoggedIn: true,
          phoneNumber: phoneNumber,
          token: responseData['token'] ?? '',
        );
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Invalid phone number or password';
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = 'Connection error. Please try again later.';
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedIn = false;
    _phoneNumber = '';
    _token = '';
    notifyListeners();
  }
}