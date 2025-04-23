import 'location.dart';

class ServiceProvider {
  final String serviceProviderId;
  final String businessName;
  final String email;
  final String phoneNumber;
  final String serviceType;
  final Location? location;
  final String profilePicture;

  ServiceProvider({
    required this.serviceProviderId,
    required this.businessName,
    required this.email,
    required this.phoneNumber,
    required this.serviceType,
    this.location,
    required this.profilePicture,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      serviceProviderId: json['id'].toString(),
      businessName: json['businessName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      serviceType: json['serviceType'] ?? '',
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      profilePicture: json['profilePicture'] ?? '',
    );
  }
}
