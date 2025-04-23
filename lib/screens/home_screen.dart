import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider_app/bottomnavbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAvailable = false;
  String? providerId;
 // Bottom navbar index
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    loadProviderId();
  }

  Future<void> loadProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone_number');
    if (phone != null) {
      await fetchProviderIdByPhone(phone);
    } else {
      print("Phone number not found in local storage.");
    }
  }

  Future<void> fetchProviderIdByPhone(String phone) async {
    final url = Uri.parse("https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/providers/by-phone/$phone");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        providerId = data['service_provider_id'].toString();
      });
    } else {
      print("Failed to fetch provider ID. Status: ${response.statusCode}");
    }
  }

  Future<void> toggleAvailability() async {
    if (providerId == null) {
      print("Provider ID is null.");
      return;
    }

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
      print("⛔ Failed to update availability. Status: ${response.statusCode}");
      print("Response: ${response.body}");
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
      body: Center(
        child: providerId == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Availability: ${isAvailable ? "Online" : "Offline"}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: toggleAvailability,
                    child: Text(
                      isAvailable ? "Go Offline" : "Go Online",
                    ),
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
