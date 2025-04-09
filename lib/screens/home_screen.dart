import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider_app/bottomnavbar.dart';

final logger = Logger();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAvailable = false;
  String providerId = "your_service_provider_id";
  List<File> _images = [];  // Store multiple images
  bool _isUploading = false;

  // Bottom navbar index
  int _selectedIndex = 0;

  // Availability Toggle
  Future<void> toggleAvailability() async {
    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$providerId/availability');
    final updatedAvailability = {'available': !isAvailable};

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(updatedAvailability),
    );

    if (!mounted) return; // Check if the widget is still mounted
    if (response.statusCode == 200) {
      setState(() {
        isAvailable = !isAvailable;
      });
    } else {
      logger.e('Failed to update availability');
    }
  }

  // Pick multiple images
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
      });
    }
  }

  // Upload images
  Future<void> _uploadImages() async {
    if (_images.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    final url = Uri.parse('https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$providerId/upload-images');

    var request = http.MultipartRequest('POST', url);

    // Add each image to the request
    for (var image in _images) {
      request.files.add(await http.MultipartFile.fromPath('files', image.path));
    }

    try {
      var response = await request.send();

      if (!mounted) return; // Check if the widget is still mounted
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Images uploaded successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload images')));
      }
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading images')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
      Navigator.pushNamed(context, '/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAvailable ? 'You are available!' : 'You are unavailable',
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: Icon(
                    isAvailable ? Icons.check_circle : Icons.remove_circle,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                  onPressed: toggleAvailability,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Upload Service Images'),
                ElevatedButton(
                  onPressed: _pickImages,
                  child: const Text('Pick Images'),
                ),
                if (_images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Image.file(_images[index]);
                      },
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadImages,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Upload Images'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
