// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider_app/bottomnavbar.dart';

class ServiceProvider {
  String serviceProviderId;
  String email;
  String phoneNumber;
  String? location;
  double? latitude;
  double? longitude;
  String serviceType;
  String profilePicture;
  String businessName;
  Map<String, bool> availability;

  ServiceProvider({
    required this.serviceProviderId,
    required this.email,
    required this.phoneNumber,
    this.location,
    this.latitude,
    this.longitude,
    required this.serviceType,
    required this.profilePicture,
    required this.businessName,
    required this.availability,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'location': {'latitude': latitude, 'longitude': longitude},
      'serviceType': serviceType,
      'profilePicture': profilePicture,
      'businessName': businessName,
      'availability': availability,
    };
  }

  static ServiceProvider fromJson(Map<String, dynamic> json) {
    String? locationString;
    double? lat;
    double? lng;

    if (json['location'] is String) {
      locationString = json['location'];
    } else if (json['location'] is Map) {
      final locationMap = json['location'] as Map;
      lat =
          locationMap['latitude'] is num
              ? (locationMap['latitude'] as num).toDouble()
              : null;
      lng =
          locationMap['longitude'] is num
              ? (locationMap['longitude'] as num).toDouble()
              : null;
      locationString = lat != null && lng != null ? "$lat, $lng" : null;
    }

    return ServiceProvider(
      serviceProviderId: json['service_provider_id'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      location: locationString,
      latitude: lat,
      longitude: lng,
      serviceType: json['service_type'] ?? json['serviceType'] ?? '',
      profilePicture: json['profile_picture'] ?? json['profilePicture'] ?? '',
      businessName: json['business_name'] ?? json['businessName'] ?? '',
      availability:
          json['availability'] != null && json['availability'] is Map
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
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  Uint8List? _profileImageBytes;

  int _selectedIndex = 3; // Default to 'Settings' tab

  ServiceProvider? currentProvider;
  String? _errorMessage;
  String? providerId;

  // Helper function to extract numeric ID from custom ID format
 int _extractNumericId(String customId) {
  final numericPart = customId.replaceAll(RegExp(r'[^0-9]'), '');
  final id = int.tryParse(numericPart) ?? 0; 
  
  // Add debugging to see what's being extracted
  print('Original ID: $customId, Extracted numeric part: $numericPart, Parsed ID: $id');
  
  // If ID is 0, there might be an issue with extraction
  if (id == 0 && numericPart.isEmpty) {
    // Use the full ID if we couldn't extract a numeric part
    return 0; // You might want to handle this differently
  }
  
  return id;
}
  @override
  void initState() {
    super.initState();
    loadProviderId();
  }

  Future<void> loadProviderId() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');

    if (phone != null) {
      await fetchProviderIdByPhone(phone);
    } else {
      print("Phone number not found in local storage.");
      setState(() {
        _errorMessage = 'Phone number not found. Please log in again.';
        _isLoading = false;
      });
    }
    if (_errorMessage == 'Phone number not found. Please log in again.') {
  Future.delayed(Duration.zero, () {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  });
}

  }

  Future<void> fetchProviderIdByPhone(String phone) async {
    final url = Uri.parse(
      "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/serviceprovider?phoneNumber=$phone",
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          providerId = data['service_provider_id'].toString();
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('serviceProviderId', providerId!);

        await _fetchServiceProviderDetails();
      } else {
        print("Failed to fetch provider ID. Status: ${response.statusCode}");
        setState(() {
          _errorMessage =
              'Failed to fetch provider ID. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching provider ID: $e");
      setState(() {
        _errorMessage = 'Error fetching provider ID: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchServiceProviderDetails() async {
    if (providerId == null) {
      setState(() {
        _errorMessage = 'Provider ID is missing. Please try again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('authToken');

      final numericId = _extractNumericId(providerId!); // Convert to numeric ID
      final headers = {'Authorization': 'Bearer $authToken'};
      final url = Uri.parse(
        'https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$numericId',
      );

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final providerData = json.decode(response.body);
        setState(() {
          currentProvider = ServiceProvider.fromJson(providerData);
          _populateControllers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch provider details. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching provider details: $e';
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (currentProvider != null) {
      _emailController.text = currentProvider!.email;
      _phoneController.text = currentProvider!.phoneNumber;
      _businessNameController.text = currentProvider!.businessName;
      _serviceTypeController.text = currentProvider!.serviceType;

      if (currentProvider!.latitude != null &&
          currentProvider!.longitude != null) {
        _locationController.text =
            '${currentProvider!.latitude!.toStringAsFixed(6)}, ${currentProvider!.longitude!.toStringAsFixed(6)}';
      } else {
        _locationController.text = currentProvider!.location ?? '';
      }

      if (currentProvider!.profilePicture.isNotEmpty) {
        try {
          _profileImageBytes = base64.decode(currentProvider!.profilePicture);
        } catch (e) {
          print('Error decoding profile picture: $e');
        }
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
      print('Image selected from: ${pickedFile.path}');
    }
  }

  Future<void> _updateServiceProvider() async {
    if (currentProvider == null || providerId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('authToken');

      currentProvider!.email = _emailController.text;
      currentProvider!.phoneNumber = _phoneController.text;
      currentProvider!.businessName = _businessNameController.text;
      currentProvider!.serviceType = _serviceTypeController.text;

      if (_locationController.text.isNotEmpty) {
        final locationParts = _locationController.text.split(',');
        if (locationParts.length == 2) {
          try {
            currentProvider!.latitude = double.parse(locationParts[0].trim());
            currentProvider!.longitude = double.parse(locationParts[1].trim());
            currentProvider!.location = _locationController.text;
          } catch (e) {
            setState(() {
              _errorMessage =
                  'Invalid location format. Please use: latitude, longitude';
              _isLoading = false;
            });
            return;
          }
        } else {
          currentProvider!.location = _locationController.text;
        }
      } else {
        currentProvider!.location = null;
        currentProvider!.latitude = null;
        currentProvider!.longitude = null;
      }

      if (_profileImageBytes != null) {
        currentProvider!.profilePicture = base64.encode(_profileImageBytes!);
      }

      final url = Uri.parse(
        'https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$providerId/details',
      );
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(currentProvider!.toJson()),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details updated successfully')),
        );
      } else {
        setState(() {
          _errorMessage =
              'Failed to update details. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
  setState(() {
    _isLoading = true;
  });

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authToken');

    await prefs.clear(); // Clear all saved data

    final url = Uri.parse(
      'https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/logout',
    );
    final response = await http.post(
  url,
  headers: {'Authorization': 'Bearer $authToken'},
);

if (response.statusCode == 200) {
  print("Logout successful");
} else {
  print("Logout failed: ${response.statusCode}");
}

    // Always navigate to splash/login and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/splash', // or '/login' if you prefer
      (Route<dynamic> route) => false,
    );
  } catch (e) {
    print('Error during logout: $e');
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }
}


  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

   if (index == 0) {
    Navigator.pushNamed(context, '/home');
  } else if (index == 1) {
    Navigator.pushNamed(context, '/gallery');
  } else if (index == 2) {
    Navigator.pushNamed(context, '/appointments');
  } else if (index == 3) {
    Navigator.pushNamed(context, '/settings');
  }
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller, {
    bool enabled = false,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed:
                _isLoading
                    ? null
                    : (_isEditing ? _updateServiceProvider : _toggleEditMode),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                )
                : currentProvider == null
                ? const Center(child: Text('No provider data available'))
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                    _profileImageBytes != null
                                        ? MemoryImage(_profileImageBytes!)
                                        : null,
                                child:
                                    _profileImageBytes == null
                                        ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        )
                                        : null,
                              ),
                              if (_isEditing)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoField(
                          'Email',
                          _emailController,
                          enabled: _isEditing,
                          prefixIcon: Icons.email,
                        ),
                        _buildInfoField(
                          'Phone Number',
                          _phoneController,
                          enabled: _isEditing,
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildInfoField(
                          'Business Name',
                          _businessNameController,
                          enabled: _isEditing,
                          prefixIcon: Icons.business,
                        ),
                        _buildInfoField(
                          'Service Type',
                          _serviceTypeController,
                          enabled: _isEditing,
                          prefixIcon: Icons.work,
                        ),
                        _buildInfoField(
                          'Location',
                          _locationController,
                          enabled: _isEditing,
                          prefixIcon: Icons.location_on,
                          hintText: 'Format: latitude, longitude',
                        ),
                        const SizedBox(height: 32),
                        if (!_isEditing)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
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
