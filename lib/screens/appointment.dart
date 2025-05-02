import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider_app/Models/appointment.dart';
import 'package:provider_app/bottomnavbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String get fullName => '$firstName $lastName';
}

class AppointmentScreen extends StatefulWidget {
  final Appointment? appointment;
  
  const AppointmentScreen({super.key, this.appointment});

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  List<Appointment> appointments = [];
  Map<String, User> users = {};
  bool isLoading = true;
  String? providerId;
  int _selectedIndex = 1; // Default to 'Appointments' tab
  
  // Filter options
  String _filterStatus = "All";
  final List<String> _statusOptions = ["All", "Pending", "Confirmed", "Completed", "Cancelled"];
  
  @override
  void initState() {
    super.initState();
    loadProviderId();
  }

  Future<void> loadProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    
    if (phone != null) {
      await fetchProviderIdByPhone(phone);
    } else {
      print("Phone number not found in local storage.");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchProviderIdByPhone(String phone) async {
    final url = Uri.parse(
        "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/serviceprovider?phoneNumber=$phone");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        providerId = data['service_provider_id'].toString();
      });
      await fetchAppointments();
    } else {
      print("Failed to fetch provider ID. Status: ${response.statusCode}");
      setState(() {
        isLoading = false;
      });
    }
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
        // Sort appointments by date (newest first)
        appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      });
      
      // Fetch user details for each appointment
      await fetchUsersData();
    } else {
      print("Failed to load appointments: ${response.statusCode}");
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> fetchUsersData() async {
    // Get unique user IDs from appointments
    final Set<String> uniqueUserIds = appointments.map((a) => a.userId).toSet();
    
    // Create a map to store fetched users
    Map<String, User> fetchedUsers = {};
    
    // Fetch user data for each unique user ID
    for (String userId in uniqueUserIds) {
      try {
        final userUrl = Uri.parse(
          "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/users/findByUserId/$userId"
        );
        
        final userResponse = await http.get(userUrl);
        
        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          fetchedUsers[userId] = User.fromJson(userData);
        } else {
          print("Failed to fetch user data for $userId: ${userResponse.statusCode}");
          // Create a placeholder user with just the ID
          fetchedUsers[userId] = User(
            userId: userId,
            firstName: 'User',
            lastName: userId.substring(0, 3),
            profilePicture: null,
          );
        }
      } catch (e) {
        print("Error fetching user data: $e");
        // Create a placeholder user for error cases
        fetchedUsers[userId] = User(
          userId: userId,
          firstName: 'User',
          lastName: userId.substring(0, 3),
          profilePicture: null,
        );
      }
    }
    
    setState(() {
      users = fetchedUsers;
      isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      // Already on appointments
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
    }
  }
  
  List<Appointment> getFilteredAppointments() {
    if (_filterStatus == "All") {
      return appointments;
    } else {
      return appointments.where((appointment) => 
        appointment.status.toLowerCase() == _filterStatus.toLowerCase()
      ).toList();
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
  
  Future<void> _updateAppointmentStatus(Appointment appointment, String newStatus) async {
    setState(() {
      isLoading = true;
    });
    
    final url = Uri.parse(
        "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/appointments/${appointment.serviceProviderId}/appointments/${appointment.userId}/status");
    
    final updatedAppointment = {
      'status': newStatus,
    };
    
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedAppointment),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment status updated to $newStatus'))
        );
        fetchAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update appointment status: ${response.body}'))
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error updating appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while updating appointment'))
      );
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _showAppointmentOptions(Appointment appointment) {
    final user = users[appointment.userId];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Appointment Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailsRow("Date", DateFormat('MMMM d, yyyy').format(appointment.appointmentDate.toLocal())),
              _buildDetailsRow("Time", DateFormat('h:mm a').format(appointment.appointmentDate.toLocal())),
              _buildDetailsRow("Client", user?.fullName ?? "Unknown User"),
              _buildDetailsRow("Status", appointment.status),
              const SizedBox(height: 24),
              Text(
                "Update Status",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusButton("Pending", Colors.orange, appointment),
                  _buildStatusButton("Confirmed", Colors.green, appointment),
                  _buildStatusButton("Completed", Colors.blue, appointment),
                  _buildStatusButton("Cancelled", Colors.red, appointment),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusButton(String status, Color color, Appointment appointment) {
    bool isCurrentStatus = appointment.status.toLowerCase() == status.toLowerCase();
    
    return GestureDetector(
      onTap: isCurrentStatus 
          ? null 
          : () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointment, status);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentStatus ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color,
            width: 1,
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isCurrentStatus ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = getFilteredAppointments();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "All Appointments",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: fetchAppointments,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            )
          : Column(
              children: [
                // Filter bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Filter by status",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statusOptions.map((status) {
                            final isSelected = _filterStatus == status;
                            Color statusColor;
                            
                            switch (status.toLowerCase()) {
                              case 'confirmed': statusColor = Colors.green; break;
                              case 'completed': statusColor = Colors.blue; break;
                              case 'cancelled': statusColor = Colors.red; break;
                              case 'pending': statusColor = Colors.orange; break;
                              default: statusColor = Colors.grey; break;
                            }
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _filterStatus = status;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? statusColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${filteredAppointments.length} appointment${filteredAppointments.length != 1 ? 's' : ''} found",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Appointments list
                Expanded(
                  child: filteredAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_busy,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filterStatus == "All"
                                    ? "No appointments found"
                                    : "No $_filterStatus appointments",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Try changing your filter or refresh",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchAppointments,
                          color: Theme.of(context).primaryColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAppointments.length,
                            itemBuilder: (context, index) {
                              final appt = filteredAppointments[index];
                              final formattedDate = DateFormat('MMM d, yyyy • h:mm a')
                                  .format(appt.appointmentDate.toLocal());
                              final user = users[appt.userId];
                              
                              // Group appointments by date
                              final bool isFirstOfDay = index == 0 ||
                                  DateFormat('yyyy-MM-dd').format(filteredAppointments[index].appointmentDate) !=
                                  DateFormat('yyyy-MM-dd').format(filteredAppointments[index - 1].appointmentDate);
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isFirstOfDay) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                                      child: Text(
                                        DateFormat('EEEE, MMMM d').format(appt.appointmentDate.toLocal()),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Container(
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
                                      leading: user?.profilePicture != null
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(user!.profilePicture!),
                                            backgroundColor: Colors.grey[200],
                                          )
                                        : CircleAvatar(
                                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                            child: Text(
                                              user?.firstName.substring(0, 1).toUpperCase() ?? 
                                              appt.userId.substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      title: Row(
                                        children: [
                                          Flexible(
                                            flex: 3,
                                            child: Text(
                                              user?.fullName ?? 'User ID: ${appt.userId}',
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
                                      trailing: IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () => _showAppointmentOptions(appt),
                                      ),
                                      onTap: () => _showAppointmentOptions(appt),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
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