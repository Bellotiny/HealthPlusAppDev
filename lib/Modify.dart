import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'AppointmentDatabase.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class ModifyScreen extends StatefulWidget {
  final Appointment appointment;

  const ModifyScreen({Key? key, required this.appointment}) : super(key: key);

  @override
  _ModifyScreenState createState() => _ModifyScreenState();
}

class _ModifyScreenState extends State<ModifyScreen> {
  TextEditingController addressController = TextEditingController();
  Map<String, dynamic>? selectedDoctor;
  String? selectedSchedulePath;
  DateTime? selectedDate;
  String? selectedSlot;
  List<String> availableDays = [];
  List<Map<String, dynamic>> availableSlots = [];
  LatLng _initialLocation = LatLng(45.5017, -73.5673);

  @override
  void initState() {
    super.initState();

    // Pre-fill fields from the appointment
    addressController.text = widget.appointment.location;
    selectedSlot = widget.appointment.time;

    try {
      selectedDate = DateFormat('yyyy-MM-dd').parse(widget.appointment.date);
    } catch (e) {
      print('Error parsing date: ${widget.appointment.date}');
      selectedDate = DateTime.now();
    }

    if (widget.appointment.doctor != null) {
      _fetchDoctorSchedule(widget.appointment.doctor!);
    }
  }

  Future<void> _fetchDoctorSchedule(String doctorName) async {
    try {
      // Fetch the doctor's details (including schedule) from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Doctors')
          .where('doctor', isEqualTo: doctorName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doctorData = querySnapshot.docs.first;
        final scheduleReference = doctorData['schedule'] as DocumentReference;

        // Fetch the schedule details using the schedule reference
        await _fetchScheduleDetails(scheduleReference.id);

        setState(() {
          selectedDoctor = {
            "name": doctorName,
            "schedule": scheduleReference.id,
          };
        });
      } else {
        print("No schedule found for doctor: $doctorName");
      }
    } catch (e) {
      print("Error fetching doctor schedule: $e");
    }
  }

  Future<void> _fetchScheduleDetails(String scheduleName) async {
    try {
      // Fetch the schedule details from Firestore
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance
          .collection('Schedules')
          .doc(scheduleName)
          .get();

      if (scheduleDoc.exists) {
        Map<String, dynamic> scheduleData =
        scheduleDoc.data() as Map<String, dynamic>;

        // Extract available days and slots
        setState(() {
          availableDays = scheduleData['week'].keys.toList();
        });

        // Fetch slots for the first available day (optional)
        if (availableDays.isNotEmpty) {
          _fetchAvailableSlots(scheduleName, availableDays.first);
        }
      } else {
        print("Schedule document not found: $scheduleName");
      }
    } catch (e) {
      print("Error fetching schedule details: $e");
    }
  }

  Future<void> _fetchAvailableSlots(String scheduleName, String dayName) async {
    try {
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance
          .collection('Schedules')
          .doc(scheduleName)
          .get();

      if (scheduleDoc.exists) {
        Map<String, dynamic> scheduleData =
        scheduleDoc.data() as Map<String, dynamic>;

        List<dynamic> slots = scheduleData['week'][dayName] ?? [];

        setState(() {
          availableSlots = slots
              .where((slot) => slot['status'] == 'available')
              .map((slot) => {"time": slot['time'], "status": slot['status']})
              .toList();

          // Reset selectedSlot if it is no longer valid
          if (!availableSlots.any((slot) => slot['time'] == selectedSlot)) {
            selectedSlot = null; // Reset to null if the selected slot isn't available
          }
        });

        print("Available slots for $dayName: $availableSlots");
      } else {
        print("Schedule document not found: $scheduleName");
      }
    } catch (e) {
      print("Error fetching available slots: $e");
    }
  }

  void saveChanges() async {
    try {
      // Validate required fields
      if (selectedDate == null || selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a valid date and time slot.')),
        );
        return;
      }

      final updatedAppointment = Appointment(
        id: widget.appointment.id,
        location: addressController.text,
        doctor: widget.appointment.doctor ?? "Unknown Doctor",
        date: selectedDate!.toIso8601String().split('T')[0],
        time: selectedSlot!,
        email: widget.appointment.email,
      );

      await Provider.of<DatabaseAccess>(context, listen: false)
          .updateAppointment(widget.appointment.id!, updatedAppointment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment successfully modified!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to modify appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Modify Appointment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: addressController,
              readOnly: true,
              decoration: InputDecoration(
                labelText:'${bundle.translation('location')}',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: widget.appointment.doctor), // Directly set the doctor's name
              readOnly: true,
              decoration: InputDecoration(
                labelText: '${bundle.translation('doctor')}',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(Duration(days: 30)),
              focusedDay: selectedDate ?? DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                String dayName = DateFormat('EEEE').format(selectedDay);
                if (availableDays.contains(dayName)) {
                  setState(() {
                    selectedDate = selectedDay;
                    _fetchAvailableSlots(
                        selectedDoctor?['schedule'], dayName);
                  });
                }
              },
            ),
            DropdownButton<String>(
              value: selectedSlot,
              items: availableSlots.map((slot) {
                return DropdownMenuItem<String>(
                  value: slot['time'],
                  child: Text(slot['time']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSlot = value;
                });
              },
              hint: Text(bundle.translation('selectTime')), // Provide a default hint if no slot is selected
            ),
            ElevatedButton(
              onPressed: saveChanges,
              child: Text(bundle.translation('save')),
            ),
          ],
        ),
      ),
    );
  }
}
