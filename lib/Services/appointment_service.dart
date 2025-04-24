import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/appointment.dart';

class AppointmentService {
  static const String baseUrl = 'https://salty-citadel-42862-262ec2972a46.herokuapp.com/api/appointments';

  static Future<List<Appointment>> fetchAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/all'));
    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((e) => Appointment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  static Future<void> updateAppointment(Appointment appointment) async {
    final id = {
      "user_id": appointment.userId,
      "service_provider_id": appointment.serviceProviderId
    };
    final response = await http.put(
      Uri.parse('$baseUrl/update/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(appointment.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment');
    }
  }
}
