// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the shared_preferences package
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;  // Variable to track password visibility

Future<void> _login() async {
  setState(() {
    _isLoading = true;
  });

  final bool success = await Provider.of<AuthProvider>(context, listen: false)
      .login(_phoneController.text, _passwordController.text);

  setState(() {
    _isLoading = false;
  });

  if (success) {
    // Store the phone number in SharedPreferences after successful login
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('phoneNumber', _phoneController.text);
    
    // Log to ensure the phone number is saved
    String? storedPhoneNumber = prefs.getString('phoneNumber');
    print('Stored phone number: $storedPhoneNumber');

    // Navigate to home screen if login is successful
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    // Show error message if login fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage)),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,  // Toggle the visibility based on _isPasswordVisible
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;  // Toggle the visibility
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
