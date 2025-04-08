import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController pricePerHourController = TextEditingController();

  String selectedServiceType = 'Plumber';
  final List<String> serviceTypes = [
    'Plumber',
    'Electrician',
    'Painter',
    'Mechanic',
    'Carpenter',
    'Mason',
    'Welder',
    'Gardener',
    'Cleaner',
    'Tailor',
    'Hairdresser',
    'Makeup Artist',
    'Chef',
    'Baker',
    'Butcher',
    'Barber',
    'Auto Body Technician',
    'Heavy Equipment Operator',
    'Refrigeration and AC Technician',
    'Upholsterer',
    'Blacksmith',
    'Tiler',
    'Roofer',
    'Pest Control Technician',
    'Construction Worker',
    'Shoemaker',
    'Bricklayer',
    'Furniture Maker',
    'Vehicle Spray Painter',
    'Laundry Worker',
    'Housekeeper',
    'Motorcycle Repair Technician',
    'Solar Panel Installer',
    'CCTV Installer',
    'Driver (Commercial/Private)'
  ];

  bool isPasswordVisible = false;

  // Profile picture file
  File? _profileImage;

  // Location variables
  double? _latitude;
  double? _longitude;
  bool _locationPicked = false;

  @override
  void dispose() {
    businessNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    descriptionController.dispose();
    pricePerHourController.dispose();
    super.dispose();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    // Request permission for photos/gallery if not granted
    final status = await Permission.photos.request();
    if (status.isGranted) {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission denied')),
      );
    }
  }

  // Function to pick location (here we simulate by getting current location)
  Future<void> _pickLocation() async {
    // Request location permission
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      return;
    }
    // For demonstration, get current location.
    // In your production app, replace this with an interactive map location picker.
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationPicked = true;
    });
  }

  // Function to register the service provider
  Future<void> registerServiceProvider() async {
    final String url = getBaseUrl() + '/api/providers/register'; // Updated to match backend URL
    final Map<String, String> headers = {'Content-Type': 'application/json'};

    // Prepare the body of the POST request with form data
    final body = json.encode({
      'businessName': businessNameController.text,
      'email': emailController.text,
      'phoneNumber': phoneNumberController.text,
      'password': passwordController.text,
      'serviceType': selectedServiceType,
      'latitude': _latitude,
      'longitude': _longitude,
      'description': descriptionController.text,
      'pricePerHour': pricePerHourController.text,
    });

    try {
      // Send the POST request to the backend
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      // Handle the backend response
      if (response.statusCode == 200) {
        // Registration successful, handle success (e.g., show a message or navigate)
        print('Service Provider registered successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service Provider registered successfully')),
        );
      } else if (response.statusCode == 400) {
        // Handle the case where the email is already in use
        final errorMessage = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else {
        // Handle any other error (e.g., server error)
        print('Failed to register: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed, try again later')),
        );
      }
    } catch (error) {
      // Handle network or other errors
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred, please try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Business Name
              TextFormField(
                controller: businessNameController,
                decoration:
                    const InputDecoration(labelText: 'Business Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter business name' : null,
              ),

              // Email
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter email' : null,
              ),

              // Phone Number
              TextFormField(
                controller: phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter phone number' : null,
              ),

              // Password
              TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'Minimum 6 characters required'
                    : null,
              ),

              // Service Type Dropdown
              DropdownButtonFormField<String>(
                value: selectedServiceType,
                items: serviceTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedServiceType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Service Type'),
              ),

              // Location Picker
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.location_on),
                      label: Text(_locationPicked
                          ? 'Location Selected'
                          : 'Select Location'),
                      onPressed: _pickLocation,
                    ),
                  ),
                ],
              ),
              if (_locationPicked && _latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected Location: ($_latitude, $_longitude)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

              // Description
              TextFormField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Business Description'),
                maxLines: 3,
              ),

              // Price Per Hour
              TextFormField(
                controller: pricePerHourController,
                decoration:
                    const InputDecoration(labelText: 'Price per Hour'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // Register Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Call the method to register the service provider
                    registerServiceProvider();
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com'; // Use Heroku URL for Android
    } else if (Platform.isIOS) {
      return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com'; // Use Heroku URL for iOS
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:8080'; // Use localhost for local testing on PC
    }
    return 'https://salty-citadel-42862-262ec2972a46.herokuapp.com'; // Default for other cases
  }
}
