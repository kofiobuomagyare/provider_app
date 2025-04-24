class Appointment {
  final String userId;
  final String serviceProviderId;
  final DateTime appointmentDate;
  String status; // mutable so we can update it

  Appointment({
    required this.userId,
    required this.serviceProviderId,
    required this.appointmentDate,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      userId: json['user_id'],
      serviceProviderId: json['service_provider_id'],
      appointmentDate: DateTime.parse(json['appointmentDate']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'service_provider_id': serviceProviderId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': status,
    };
  }
}