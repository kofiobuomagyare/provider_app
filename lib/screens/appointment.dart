import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider_app/bottomnavbar.dart'; // ✅ Import the bottom navbar

class Appointment {
  String userId;
  String serviceProviderId;
  DateTime appointmentDate;
  String status;

  Appointment({
    required this.userId,
    required this.serviceProviderId,
    required this.appointmentDate,
    required this.status,
  });

  // Convert Appointment to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'service_provider_id': serviceProviderId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': status,
    };
  }

  // From JSON response
  static Appointment fromJson(Map<String, dynamic> json) {
    return Appointment(
      userId: json['user_id'],
      serviceProviderId: json['service_provider_id'],
      appointmentDate: DateTime.parse(json['appointmentDate']),
      status: json['status'],
    );
  }
}

class AppointmentService {
  final String baseUrl = 'https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/appointments';

  // Create Appointment
  Future<void> createAppointment(Appointment appointment) async {
    final url = Uri.parse('$baseUrl/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(appointment.toJson()),
    );
    
    if (response.statusCode == 200) {
      print('Appointment created successfully');
      // Show confirmation or navigate to another screen
    } else {
      print('Failed to create appointment');
    }
  }

  // Update Appointment
  Future<void> updateAppointment(String userId, String serviceProviderId, Appointment updatedAppointment) async {
    final url = Uri.parse('$baseUrl/update/$userId/$serviceProviderId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedAppointment.toJson()),
    );
    
    if (response.statusCode == 200) {
      print('Appointment updated successfully');
      // Show confirmation or navigate to another screen
    } else {
      print('Failed to update appointment');
    }
  }

  // Cancel Appointment
  Future<void> cancelAppointment(String userId, String serviceProviderId) async {
    final url = Uri.parse('$baseUrl/cancel/$userId/$serviceProviderId');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      print('Appointment canceled successfully');
      // Show confirmation or navigate to another screen
    } else {
      print('Failed to cancel appointment');
    }
  }

  // Get All Appointments (for the current user or service provider)
  Future<List<Appointment>> getAllAppointments() async {
    final url = Uri.parse('$baseUrl/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Appointment.fromJson(json)).toList();
    } else {
      print('Failed to load appointments');
      return [];
    }
  }
}

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _statusController = TextEditingController();
  bool _isLoading = false;

  int _selectedIndex = 1; // Default to 'Appointments' tab

  Future<void> _createAppointment() async {
    setState(() {
      _isLoading = true;
    });

    final appointment = Appointment(
      userId: 'user_id_example', // Replace with dynamic user id
      serviceProviderId: 'service_provider_id_example', // Replace with dynamic provider id
      appointmentDate: DateTime.now(),
      status: _statusController.text,
    );

    await _appointmentService.createAppointment(appointment);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateAppointment(String userId, String serviceProviderId) async {
    setState(() {
      _isLoading = true;
    });

    final updatedAppointment = Appointment(
      userId: userId,
      serviceProviderId: serviceProviderId,
      appointmentDate: DateTime.now(),
      status: _statusController.text,
    );

    await _appointmentService.updateAppointment(userId, serviceProviderId, updatedAppointment);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _cancelAppointment(String userId, String serviceProviderId) async {
    setState(() {
      _isLoading = true;
    });

    await _appointmentService.cancelAppointment(userId, serviceProviderId);

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
      // Already on appointments
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _createAppointment,
                        child: const Text('Create Appointment'),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateAppointment('user_id_example', 'service_provider_id_example'),
                        child: const Text('Update Appointment'),
                      ),
                      ElevatedButton(
                        onPressed: () => _cancelAppointment('user_id_example', 'service_provider_id_example'),
                        child: const Text('Cancel Appointment'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
