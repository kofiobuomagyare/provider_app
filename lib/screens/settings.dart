import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';  // Import shared_preferences

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
      'phoneNumber': phoneNumber,
      'location': location,
      'serviceType': serviceType,
      'profilePicture': profilePicture,
      'businessName': businessName,
      'availability': availability,
    };
  }

  static ServiceProvider fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      serviceProviderId: json['service_provider_id'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      location: json['location'],
      serviceType: json['service_type'],
      profilePicture: json['profile_picture'],
      businessName: json['business_name'],
      availability: Map<String, bool>.from(json['availability']),
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
  File? _image;
  bool _isLoading = false;

  int _selectedIndex = 2; // ✅ Default to 'Settings' tab

  // Simulated current provider
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

  Future<void> _fetchServiceProviderDetails() async {
    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/${currentProvider.serviceProviderId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final providerData = json.decode(response.body);
      setState(() {
        currentProvider = ServiceProvider.fromJson(providerData);
      });
    } else {
      print('Failed to fetch provider details');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateServiceProvider() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/${currentProvider.serviceProviderId}');
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

  Future<void> _updateAvailability() async {
    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/${currentProvider.serviceProviderId}/availability');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'availability': currentProvider.availability}),
    );

    if (response.statusCode == 200) {
      print('Availability updated');
    } else {
      print('Failed to update availability');
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    // Remove session data from shared_preferences (if any)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('serviceProviderId');
    prefs.remove('authToken');  // If you're storing an auth token

    // Call the logout endpoint
    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/logout');
    final response = await http.post(url);  // Assuming you send a POST request to log out

    if (response.statusCode == 200) {
      print('Logged out');
      // Redirect to login page after successful logout
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print('Failed to log out');
    }

    setState(() {
      _isLoading = false;
    });
  }

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
    _fetchServiceProviderDetails(); // Fetch provider details on screen load
  }

  @override
  Widget build(BuildContext context) {
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
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : (currentProvider.profilePicture.isNotEmpty
                            ? NetworkImage(currentProvider.profilePicture)
                            : const AssetImage('assets/default_profile.png')) as ImageProvider,
                    child: _image == null
                        ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                  onChanged: (value) => setState(() {
                    currentProvider.businessName = value;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) => setState(() {
                    currentProvider.email = value;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  onChanged: (value) => setState(() {
                    currentProvider.phoneNumber = value;
                  }),
                ),
                const SizedBox(height: 16),
                Column(
                  children: currentProvider.availability.keys.map((day) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Available on $day'),
                        Switch(
                          value: currentProvider.availability[day] ?? false,
                          onChanged: (value) {
                            setState(() {
                              currentProvider.availability[day] = value;
                            });
                            _updateAvailability();
                          },
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Privacy Settings'),
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _updateServiceProvider,
                        child: const Text('Save Changes'),
                      ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
