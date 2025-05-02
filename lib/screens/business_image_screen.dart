import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider_app/bottomnavbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessImagesScreen extends StatefulWidget {
  const BusinessImagesScreen({super.key});

  @override
  _BusinessImagesScreenState createState() => _BusinessImagesScreenState();
 
}

class _BusinessImagesScreenState extends State<BusinessImagesScreen> {
  final TextEditingController _captionController = TextEditingController();
  
  String? providerId;
  List<BusinessImage> businessImages = [];
  bool isLoading = true;
  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;
   int _selectedIndex = 1; // Default to 'Gallery' tab
  
  @override
  void initState() {
    super.initState();
    _loadProviderId();
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    
    if (phone != null) {
      await _fetchProviderIdByPhone(phone);
    } else {
      setState(() {
        isLoading = false;
        _errorMessage = "Phone number not found in local storage.";
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
    Navigator.pushNamed(context, '/gallery');
  } else if (index == 2) {
    Navigator.pushNamed(context, '/appointments');
  } else if (index == 3) {
    Navigator.pushNamed(context, '/settings');
  }
  }
  Future<void> _fetchProviderIdByPhone(String phone) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final url = Uri.parse(
          "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/serviceprovider?phoneNumber=$phone");
      final response = await http.get(url);
  
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          providerId = data['service_provider_id'].toString();
        });
        await _fetchBusinessImages();
      } else {
        setState(() {
          _errorMessage = "Failed to fetch provider ID. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _fetchBusinessImages() async {
    if (providerId == null) return;
  
    setState(() {
      isLoading = true;
    });
    
    try {
      final url = Uri.parse(
          "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$providerId/service-images");
      final response = await http.get(url);
  
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          businessImages = jsonData.map((e) => BusinessImage.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load images: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _showAddCaptionDialog();
    }
  }
  
  Future<void> _uploadImage(String caption) async {
    if (_selectedImage == null || providerId == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final url = Uri.parse(
          "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$providerId/upload-service-image");
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add file to request
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        _selectedImage!.path,
      ));
      
      // Add caption if provided
      if (caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
          await _fetchBusinessImages();
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Upload failed';
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to upload image. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
    }
  }
  
  Future<void> _deleteImage(String imageId) async {
    if (providerId == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final url = Uri.parse(
          "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$providerId/delete-service-image/$imageId");
      final response = await http.delete(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image deleted successfully')),
          );
          await _fetchBusinessImages();
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Deletion failed';
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to delete image. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _showAddCaptionDialog() {
    _captionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image Caption'),
        content: TextField(
          controller: _captionController,
          decoration: const InputDecoration(
            hintText: 'Enter a caption for this image (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _uploadImage(_captionController.text.trim());
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }
  
  void _showImageOptions(BusinessImage image) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.fullscreen),
            title: const Text('View Full Image'),
            onTap: () {
              Navigator.pop(context);
              _showFullImage(image);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Image', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(image);
            },
          ),
        ],
      ),
    );
  }
  
  void _showFullImage(BusinessImage image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(image.caption.isNotEmpty ? image.caption : 'Business Image'),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                'https://salty-citadel-42862-262ec2972a46.herokuapp.com${image.imageUrl}',
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white54,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(BusinessImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteImage(image.id.toString());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (businessImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              "No business images yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add photos to showcase your business",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("Add First Image"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: businessImages.length,
      itemBuilder: (context, index) {
        final image = businessImages[index];
        return GestureDetector(
          onTap: () => _showImageOptions(image),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                     Image.network(
  image.imageUrl,
  fit: BoxFit.cover,
  headers: {"Content-Type": image.mimeType},
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  },
),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 20,
                            ),
                            constraints: const BoxConstraints.tightFor(
                              width: 36,
                              height: 36,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => _showFullImage(image),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (image.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      image.caption,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Business Gallery",
          style: TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isLoading && businessImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchBusinessImages,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProviderId,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildImageGrid(),
          
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading image...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (!isLoading && _errorMessage == null) 
        ? FloatingActionButton(
            onPressed: _pickImage,
            child: const Icon(Icons.add_photo_alternate),
            tooltip: 'Add Image',
          )
        : null,
         bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class BusinessImage {
  final int id;
  final String mimeType;
  final String caption;
  final DateTime uploadDate;
  
  BusinessImage({
    required this.id,
    required this.mimeType,
    required this.caption,
    required this.uploadDate,
  });
  
  factory BusinessImage.fromJson(Map<String, dynamic> json) {
    return BusinessImage(
      id: json['id'] as int,
      mimeType: json['mimeType'] as String,
      caption: json['caption'] as String? ?? '',
      uploadDate: DateTime.parse(json['uploadDate'] as String),
    );
  }

  // Helper method to get the image URL
  String get imageUrl => 'https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/image/$id';
}