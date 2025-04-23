import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider_app/bottomnavbar.dart'; // ✅ Import the bottom navbar

class ServiceProvider {
  String serviceProviderId;
  String email;
  String phoneNumber;
  String location;
  String serviceType;
  String profilePicture;
  String businessName;
  Map<String, bool> availability;

  ServiceProvider({
    required this.serviceProviderId,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.serviceType,
    required this.profilePicture,
    required this.businessName,
    required this.availability,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone_number': phoneNumber,
      'location': location,
      'service_type': serviceType,
      'profile_picture': profilePicture,
      'business_name': businessName,
      'availability': availability,
    };
  }

  static ServiceProvider fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      serviceProviderId: json['service_provider_id'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      location: json['location'] ?? '',
      serviceType: json['service+type'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      businessName: json['business_name'] ?? '',
      availability: json['availability'] != null && json['availability'] is Map
          ? Map<String, bool>.from(json['availability'])
          : {},
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  bool _isLoading = false;

  int _selectedIndex = 2; // Default to 'Settings' tab

  ServiceProvider currentProvider = ServiceProvider(
    serviceProviderId: '',
    email: 'provider@example.com',
    phoneNumber: '1234567890',
    location: 'Accra, Ghana',
    serviceType: 'Electrician',
    profilePicture: '',
    businessName: 'Provider Business',
    availability: {'Monday': true, 'Tuesday': true, 'Wednesday': true, 'Thursday': true, 'Friday': true},
  );

  // Fetch service provider details from the API
  Future<void> _fetchServiceProviderDetails() async {
    final prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phoneNumber') ?? ''; // Default to empty string if null

    if (phoneNumber.isEmpty) {
      print('Phone number is missing.');
    } else {
      print('Phone number retrieved: $phoneNumber');
    }

    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/serviceprovider?phoneNumber=$phoneNumber');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final providerData = json.decode(response.body);
      print('Provider data: $providerData'); // Log the raw JSON response
      setState(() {
        currentProvider = ServiceProvider.fromJson(providerData);
      });
    } else {
      print('Failed to fetch provider details');
    }
  }

  // Pick an image for the profile
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
      });
    }
  }

  // Update the service provider details
  Future<void> _updateServiceProvider() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phoneNumber') ?? '';

    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/serviceprovider?phoneNumber=$phoneNumber');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(currentProvider.toJson()),
    );

    if (response.statusCode == 200) {
      print('Details updated successfully');
    } else {
      print('Failed to update details');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Logout the service provider
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    // Remove session data from shared_preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('serviceProviderId');
    prefs.remove('authToken');

    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/logout');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      print('Logged out');
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print('Failed to log out');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Handle bottom navbar item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/appointments');
    } else if (index == 2) {
      // Already on settings
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.text = currentProvider.email;
    _phoneController.text = currentProvider.phoneNumber;
    _businessNameController.text = currentProvider.businessName;
    _fetchServiceProviderDetails();
  }

  @override
  Widget build(BuildContext context) {
    // Decode the base64 profile picture if available
    Uint8List? profileImageBytes = currentProvider.profilePicture.isNotEmpty
        ? base64.decode(currentProvider.profilePicture)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageBytes != null
                        ? MemoryImage(profileImageBytes)
                        : (currentProvider.profilePicture.isNotEmpty
                            ? NetworkImage(currentProvider.profilePicture)
                            : const AssetImage('assets/default_profile.png')) as ImageProvider,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                ),
                const SizedBox(height: 16),
                Text('Location: ${currentProvider.location}'),
                const SizedBox(height: 8),
                Text('Service Type: ${currentProvider.serviceType}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _updateServiceProvider,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Update Details'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _logout,
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
