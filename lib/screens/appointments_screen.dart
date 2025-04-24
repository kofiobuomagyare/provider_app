import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../Models/appointment.dart';
import '../Services/appointment_service.dart';

class AppointmentsScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentsScreen({super.key, required this.appointment});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.appointment.status;
  }

  void _updateStatus() async {
    setState(() {
      widget.appointment.status = _selectedStatus;
    });

    try {
      await AppointmentService.updateAppointment(widget.appointment);
      Navigator.pop(context);
    } catch (e) {
      print('Update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Edit Appointment'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('User ID: ${widget.appointment.userId}'),
            Text('Service Provider ID: ${widget.appointment.serviceProviderId}'),
            Text('Date: ${widget.appointment.appointmentDate.toLocal()}'),
            CupertinoSegmentedControl<String>(
              children: const {
                'Pending': Text('Pending'),
                'Accepted': Text('Accepted'),
                'Declined': Text('Declined'),
              },
              groupValue: _selectedStatus,
              onValueChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: _updateStatus,
              child: const Text('Update'),
            )
          ],
        ),
      ),
    );
  }
}