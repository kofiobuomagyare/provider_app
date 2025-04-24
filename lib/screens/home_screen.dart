// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider_app/Models/appointment.dart';
import 'package:provider_app/Screens/appointments_screen.dart';
import 'package:provider_app/bottomnavbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAvailable = false;
  String? providerId;
  int _selectedIndex = 0;
  List<Appointment> appointments = [];

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
      await fetchAppointments(); // fetch after getting ID
    } else {
      print("Failed to fetch provider ID. Status: ${response.statusCode}");
    }
  }

  Future<void> toggleAvailability() async {
    if (providerId == null) return;

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
      print("✅ Availability updated to $isAvailable");
    } else {
      print("⛔ Failed to update availability.");
    }
  }

  Future<void> fetchAppointments() async {
    if (providerId == null) return;

    final url = Uri.parse(
        "https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/appointments/$providerId/appointments");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      setState(() {
        appointments =
            jsonData.map((e) => Appointment.fromJson(e)).toList();
      });
    } else {
      print("Failed to load appointments: ${response.statusCode}");
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
        title: const Text("Home"),
      ),
      body: providerId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "Availability: ${isAvailable ? "Online ✅" : "Offline ⛔"}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: toggleAvailability,
                  child: Text(isAvailable ? "Go Offline" : "Go Online"),
                ),
                const Divider(height: 30),
                const Text(
                  "Your Appointments",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: appointments.isEmpty
                      ? const Center(child: Text("No appointments yet."))
                      : ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appt = appointments[index];
                            return ListTile(
                              title: Text('User: ${appt.userId}'),
                              subtitle: Text(
                                  '${appt.appointmentDate.toLocal()} • Status: ${appt.status}'),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AppointmentsScreen(appointment: appt),
                                  ),
                                );
                                fetchAppointments(); // refresh
                              },
                            );
                          },
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
