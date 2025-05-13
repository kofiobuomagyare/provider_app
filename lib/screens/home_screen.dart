// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider_app/models/appointment.dart';
import 'package:provider_app/bottomnavbar.dart';
import 'package:provider_app/screens/appointment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Add User model class to handle user data
class User {
  final String userId;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePicture: json['profile_picture'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool isAvailable = false;
  String? providerId;
  String providerName = "Service Provider";
  int _selectedIndex = 0;
  List<Appointment> appointments = [];
  Map<String, User> userCache = {}; // Cache to store user details
  bool isLoading = true;
  late AnimationController _animationController;
  Animation<double> _animation = AlwaysStoppedAnimation(0.0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    loadProviderId();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    final name = prefs.getString('businessName');
    
    if (name != null) {
      setState(() {
        providerName = name;
      });
    }
    
    if (phone != null) {
      await fetchProviderIdByPhone(phone);
    } else {
      print("Phone number not found in local storage.");
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchProviderIdByPhone(String phone) async {
    setState(() {
      isLoading = true;
    });
    
    final url = Uri.parse(
        "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/serviceprovider?phoneNumber=$phone");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        providerId = data['service_provider_id'].toString();
        if (data['businessName'] != null) {
          providerName = data['businessName'];
        }
        if (data['available'] != null) {
          isAvailable = data['available'] == true;
          if (isAvailable) {
            _animationController.value = 1.0;
          } else {
            _animationController.value = 0.0;
          }
        }
      });
      await fetchAppointments();
    } else {
      print("Failed to fetch provider ID. Status: ${response.statusCode}");
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> toggleAvailability() async {
    if (providerId == null) return;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/$providerId/availability");

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"available": !isAvailable}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isAvailable = !isAvailable;
      });
      if (isAvailable) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      print("✅ Availability updated to $isAvailable");
    } else {
      print("⛔ Failed to update availability.");
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchAppointments() async {
    if (providerId == null) return;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/appointments/$providerId/appointments");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      setState(() {
        appointments = jsonData.map((e) => Appointment.fromJson(e)).toList();
      });
      
      // Fetch user details for each appointment
      for (var appointment in appointments) {
        await fetchUserDetails(appointment.userId);
      }
    } else {
      print("Failed to load appointments: ${response.statusCode}");
    }
    
    setState(() {
      isLoading = false;
    });
  }

  // New method to fetch user details
  Future<void> fetchUserDetails(String userId) async {
    // Skip if we already have this user in cache
    if (userCache.containsKey(userId)) return;
    
    try {
      final url = Uri.parse(
          "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/users/findByUserId/$userId");
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          userCache[userId] = User.fromJson(userData);
        });
      } else {
        print("Failed to fetch user details for $userId: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching user details: $e");
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

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return '#4CAF50';
      case 'completed': return '#2196F3';
      case 'cancelled': return '#F44336';
      case 'pending': return '#FFC107';
      default: return '#9E9E9E';
    }
  }

  // Helper method to build profile avatar based on user data
  Widget _buildUserAvatar(String userId) {
    final user = userCache[userId];
    
    if (user != null && user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      try {
        // Decode base64 profile picture
        final decodedImage = base64Decode(user.profilePicture!);
        return CircleAvatar(
          backgroundImage: MemoryImage(decodedImage),
          radius: 24,
        );
      } catch (e) {
        print("Error decoding profile picture: $e");
      }
    }
    
    // Fallback to text avatar
    return CircleAvatar(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      radius: 24,
      child: Text(
        user != null 
            ? (user.firstName.isNotEmpty ? user.firstName[0] : '') + 
              (user.lastName.isNotEmpty ? user.lastName[0] : '')
            : userId.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper method to get user display name
  String _getUserDisplayName(String userId) {
    final user = userCache[userId];
    if (user != null) {
      return "${user.firstName} ${user.lastName}";
    }
    return "User ID: $userId";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          "Nsaano Provider",
          style: TextStyle(
            color: const Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          Colors.red,
                          Colors.green,
                          _animation.value,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isAvailable,
                    onChanged: (value) => toggleAvailability(),
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.withOpacity(0.4),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.red.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchAppointments,
              color: Theme.of(context).primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with greeting and status card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Hello, $providerName",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Status",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isAvailable ? "Online & Available" : "Offline",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isAvailable ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isAvailable ? "ACTIVE" : "INACTIVE",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Appointment statistics
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Today's\nAppointments",
                              appointments.where((a) {
                                final today = DateTime.now();
                                final apptDate = a.appointmentDate.toLocal();
                                return apptDate.year == today.year && 
                                       apptDate.month == today.month && 
                                       apptDate.day == today.day;
                              }).length.toString(),
                              Icons.event_available,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              "Pending\nRequests",
                              appointments.where((a) => 
                                a.status.toLowerCase() == 'pending').length.toString(),
                              Icons.access_time,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Upcoming appointments section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Upcoming Appointments",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/appointments');
                            },
                            child: Text(
                              "View All",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Upcoming appointments list
                      appointments.isEmpty
                          ? Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No appointments yet",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Your upcoming bookings will appear here",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: appointments.length > 3 ? 3 : appointments.length,
                              itemBuilder: (context, index) {
                                final appt = appointments[index];
                                final formattedDate = DateFormat('MMM d, yyyy • h:mm a')
                                    .format(appt.appointmentDate.toLocal());
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    leading: _buildUserAvatar(appt.userId),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: Text(
                                            _getUserDisplayName(appt.userId),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          flex: 1,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(int.parse(
                                                _getStatusColor(appt.status).substring(1, 7),
                                                radix: 16,
                                              ) | 0xFF000000).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              appt.status,
                                              style: TextStyle(
                                                color: Color(int.parse(
                                                  _getStatusColor(appt.status).substring(1, 7),
                                                  radix: 16,
                                                ) | 0xFF000000),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AppointmentScreen(appointment: appt),
                                        ),
                                      );
                                      fetchAppointments();
                                    },
                                  ),
                                );
                              },
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}