# Nsaano Provider

Nsaano Provider is the official service provider app for the Nsaano platform – a booking system connecting skilled handymen and service-based businesses to users in need of services. This Flutter app allows providers to manage bookings, update availability, and showcase their business via images.

🛠 Built for our End of Semester Project at Takoradi Technical University.

## 📲 Overview
Nsaano Provider is part of a two-sided mobile application ecosystem:

Nsaano (User Side)

Nsaano Provider (Service Provider Side)

This app allows registered service providers to:

View and manage bookings from users

Accept, decline, or update appointment status

Upload business images

Update availability

Maintain a profile

## 🚀 Features
✅ Secure Login & Registration
✅ View incoming & past appointments
✅ Change appointment status (Accepted, Declined, Completed, etc.)
✅ Upload business images to showcase services
✅ Edit provider profile
✅ View ratings and reviews (Coming Soon)
✅ Chats and real time communication (Coming Soon)
✅ Notifications (Coming Soon)

## 🧱 Tech Stack
💙 Flutter – Frontend (Dart)

🌱 Spring Boot – Backend (Java)

🐬 MySQL – Database

🧾 RESTful APIs – Communication between frontend and backend

## 📸 Screenshots
 ### Splash Screen
![Splash Screen](https://github.com/user-attachments/assets/6d974630-e8e3-4430-938d-f8ddd9f711ec)  
### Home Screen
![Home Screen](https://github.com/user-attachments/assets/040ebd8a-4024-4cda-8371-ab59597dcbcd)
### Appointment View
![Appointment View](https://github.com/user-attachments/assets/d667e825-65d2-43d7-8c8f-569a794fa11f)


## 📦 Project Structure
lib/
├── models/
│   └── appointment.dart
├── providers/
│   ├── auth_provider.dart
│   ├── provider_provider.dart
│   └── provider.dart
├── screens/
│   ├── appointment.dart
│   ├── business_image_screen.dart
│   ├── create_account.dart
│   ├── home_screen.dart
│   ├── location.dart
│   ├── login_screen.dart
│   ├── reset_password_screen.dart
│   ├── service_provider.dart
│   ├── settings.dart
│   └── splash_screen.dart
├── services/
│   └── appointment_service.dart
├── bottomnavbar.dart
└── main.dart

## ⚙️ Setup Instructions

### Clone the repository:

git clone https://github.com/your-username/nsaano-provider.git
cd nsaano-provider

### Install dependencies:

flutter pub get
Configure API base URL in services/ (e.g., api_service.dart)

### Run the app:

flutter run

✅ Make sure your emulator or device is connected.

## 🧪 Testing
Manual testing has been conducted for authentication, booking status updates, and image uploads.

Automated tests are planned for future versions.

## 🧑‍💻 Contributors
This project was built by a team of 5 students as part of our Software Engineering group project at Takoradi Technical University.

## 📄 License
This repository is for academic purposes and is not currently under an open-source license. Contact us for more info.

