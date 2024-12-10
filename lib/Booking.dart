import 'package:flutter/material.dart';
import 'package:healthplusappdev/SettingsControl.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'AppointmentDatabase.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';


class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final DatabaseAccess _db = DatabaseAccess();
  TextEditingController addressController = TextEditingController();
  String? _selectedAddress;
  LatLng _initialLocation = LatLng(45.5017, -73.5673);
  int currentBookingIndex = 0;
  User? currentUser;
  String? _notifyBy = "email";
  String? selectedDay;
  Map<String, dynamic>? selectedSlot;
  final String apiKey = "AIzaSyA5SRUdgp80WhwV7sVVwLa1wSbWNPwLQ5g";
  Set<Marker> hospitalMarkers = {};
  String? selectedSpecialty;
  Map<String, dynamic>? selectedDoctor;
  String? selectedSchedulePath;
  List<Map<String, dynamic>> doctorsList = [];
  List<String> specialties = [];
  List<String> availableDays = [];
  List<Map<String, dynamic>> availableSlots = [];
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
    _fetchCurrentLocation();
    fetchCurrentUser(); // Fetch the current user

  }
  Future<void> updateSlotStatus(String schedulePath, String day, String time, String newStatus) async {
    try {
      DocumentReference scheduleRef = FirebaseFirestore.instance.doc(schedulePath);
      DocumentSnapshot scheduleDoc = await scheduleRef.get();
      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;

      // Update the slot status
      List slots = scheduleData['week'][day];
      for (var slot in slots) {
        if (slot['time'] == time) {
          slot['status'] = newStatus;
        }
      }

      // Save back to Firestore
      await scheduleRef.update({'week': scheduleData['week']});
      print("Slot updated to $newStatus: $time on $day");
    } catch (e) {
      print("Error updating slot status: $e");
    }
  }
  Future<bool> isSlotTaken(String doctorName, String date, String time) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('doctor', isEqualTo: doctorName)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .get();

      // If any documents are found, the slot is taken
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking slot availability: $e");
      return true;
    }
  }

  Future<void> fetchCurrentUser() async {
    // Fetch the current user
    currentUser = await _db.currentUser;
    if (currentUser != null) {
      print("Current User Email: ${currentUser!.email}");
    } else {
      print("No user is logged in.");
    }
    setState(() {}); // Update the state to reflect the changes
  }
  List<String> getDatesForDays(List<String> daysOfWeek) {
    DateTime now = DateTime.now();
    List<String> availableDates = [];

    for (int i = 0; i < 28; i++) {
      DateTime date = now.add(Duration(days: i));
      String weekday = DateFormat('EEEE').format(date);

      if (daysOfWeek.contains(weekday)) {
        availableDates.add(DateFormat('yyyy-MM-dd').format(date)); // Full date
      }
    }
    return availableDates;
  }
  Future<void> markSlotAsOccupied(String schedulePath, DateTime date, String time) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance.doc(schedulePath).get();
      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;

      // Update the specific slot's status
      List<dynamic> slots = scheduleData['week'][formattedDate];
      int index = slots.indexWhere((slot) => slot['time'] == time);
      if (index != -1) {
        slots[index]['status'] = 'occupied';

        // Save updated data to Firestore
        await FirebaseFirestore.instance.doc(schedulePath).update({
          'week.$formattedDate': slots,
        });
      }
      print("Slot marked as occupied for $formattedDate at $time");
    } catch (e) {
      print("Error marking slot as occupied: $e");
    }
  }
  Future<void> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      await _fetchCurrentLocation();
    } else {
      openAppSettings();
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _initialLocation = LatLng(position.latitude, position.longitude);
      });

      await _fetchHospitals();
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _fetchHospitals() async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=${_initialLocation.latitude},${_initialLocation.longitude}"
        "&radius=20000&type=hospital&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List results = data['results'];

        Set<Marker> markers = results.map((hospital) {
          LatLng position = LatLng(
            hospital['geometry']['location']['lat'],
            hospital['geometry']['location']['lng'],
          );

          return Marker(
            markerId: MarkerId(hospital['place_id']),
            position: position,
            infoWindow: InfoWindow(
              title: hospital['name'],
              snippet: hospital['vicinity'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            onTap: () async {
              await _getAddressFromCoordinates(position);
              _fetchSpecialties(_selectedAddress!);
            },
          );
        }).toSet();

        setState(() {
          hospitalMarkers = markers;
        });
      }
    } catch (e) {
      print("Error fetching hospitals: $e");
    }
  }

  Future<void> _fetchSpecialties(String hospitalName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Doctors')
          .where('hospital', isEqualTo: hospitalName)
          .get();

      Set<String> specialtySet = querySnapshot.docs
          .map((doc) => doc['specialty'].toString())
          .toSet();

      setState(() {
        specialties = specialtySet.toList();
      });
    } catch (e) {
      print("Error fetching specialties: $e");
    }
  }

  Future<void> _fetchDoctors(String specialty) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Doctors')
          .where('hospital', isEqualTo: _selectedAddress)
          .where('specialty', isEqualTo: specialty)
          .get();

      List<Map<String, dynamic>> doctors = querySnapshot.docs.map((doc) {
        return {
          "name": doc['doctor'],
          "schedule": doc['schedule'],
        };
      }).toList();

      setState(() {
        doctorsList = doctors;
      });
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  Future<void> _fetchAvailableDays(String schedulePath) async {
    try {
      DocumentSnapshot scheduleDoc =
      await FirebaseFirestore.instance.doc(schedulePath).get();

      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;

      // Get the keys (day names) from the 'week' field
      List<String> workingDays = scheduleData['week'].keys.toList();

      setState(() {
        availableDays = workingDays; // Store available day names like ["Monday", "Friday"]
      });

      print("Available Days: $availableDays");
    } catch (e) {
      print("Error fetching available days: $e");
    }
  }

  Future<void> _fetchAvailableSlots(String schedulePath, String selectedDayName) async {
    try {
      DocumentSnapshot scheduleDoc =
      await FirebaseFirestore.instance.doc(schedulePath).get();

      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;

      List<dynamic> slots = scheduleData['week'][selectedDayName] ?? [];

      setState(() {
        availableSlots = slots
            .where((slot) => slot['status'] == 'available')
            .map((slot) => {
          "time": slot['time'],
          "status": slot['status'],
        })
            .toList();
      });

      print("Available Slots for $selectedDayName: $availableSlots");
    } catch (e) {
      print("Error fetching available slots: $e");
    }
  }


  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(coordinates.latitude, coordinates.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedAddress =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
          addressController.text = _selectedAddress ?? "Unknown location";
        });
      }
    } catch (e) {
      addressController.text = "Unable to fetch address: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Health +'),
      ),
      body: currentBookingIndex == 0
          ? buildLocation(context, bundle)
          : currentBookingIndex == 1
          ? buildDoctor(context, bundle)
          : buildDateTime(context, bundle),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentBookingIndex,
        onTap: (index) {
          setState(() {
            currentBookingIndex = index;
          });
        },
        items:  [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: '${bundle.translation('location')}',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '${bundle.translation('doctor')}',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '${bundle.translation('schedule')}',
          ),
        ],
      ),
    );
  }

  Widget buildLocation(BuildContext context, Localization bundle) {
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialLocation,
              zoom: 12,
            ),
            markers: hospitalMarkers,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: addressController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: "${bundle.translation('selectedLocation')}",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedAddress != null
              ? () {
            setState(() {
              currentBookingIndex = 1;
            });
          }
              : null,
          child: Text("${bundle.translation('next')}"),
        ),
      ],
    );
  }

  Widget buildDoctor(BuildContext context, Localization bundle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Specialty Dropdown
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "${bundle.translation('selectedSpecialty')}",
            style: TextStyle(fontSize: bundle.currentLanguage == 'EN' ? 36:26, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: DropdownButton<String>(
            value: selectedSpecialty,
            items: specialties.map((specialty) {
              return DropdownMenuItem(
                value: specialty,
                child: Text(specialty, style: TextStyle(fontSize: 25)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSpecialty = value;
                doctorsList = [];
                selectedDoctor = null;
                print("Selected Specialty: $selectedSpecialty");
                _fetchDoctors(value!);
              });
            },
          ),
        ),
        SizedBox(height: 40,),

        // Doctor Dropdown (if doctors are available)
        if (doctorsList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "${bundle.translation('selectedDoctor')}",
              style: TextStyle(fontSize: bundle.currentLanguage == 'EN' ? 36:26, fontWeight: FontWeight.bold),
            ),
          ),
        if (doctorsList.isNotEmpty)
          Center(
            child: DropdownButton<Map<String, dynamic>>(
              value: selectedDoctor,
              items: doctorsList.map((doctor) {
                return DropdownMenuItem(
                  value: doctor,
                  child: Text(doctor['name'], style: TextStyle(fontSize: 25)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDoctor = value;
                  selectedSchedulePath = (value?['schedule'] as DocumentReference).path;
                  print("Selected Doctor: ${selectedDoctor?['name']}");
                  print("Selected Schedule Path: $selectedSchedulePath");
                });
              },
            ),
          ),

        // Next Button
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: ElevatedButton(
            onPressed: selectedDoctor != null
                ? () {
              setState(() {
                currentBookingIndex = 2;
              });
              _fetchAvailableDays(selectedSchedulePath!);
            }
                : null,
            child: Text("${bundle.translation('next')}"),
          ),
        ),
      ],
    );
  }


  Widget buildDateTime(BuildContext context, Localization bundle) {
    return Column(
      children: [
        // Calendar Widget
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(Duration(days: 30)),
          focusedDay: selectedDate ?? DateTime.now(),
          selectedDayPredicate: (day) =>
          selectedDate != null && isSameDay(selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            String selectedDayName = DateFormat('EEEE').format(selectedDay); // Get the day name
            print("Selected Day: $selectedDayName");

            if (availableDays.contains(selectedDayName)) {
              setState(() {
                selectedDate = selectedDay;
                _fetchAvailableSlots(selectedSchedulePath!, selectedDayName);
              });
            } else {
              print("Day not available: $selectedDayName");
            }
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              String dayName = DateFormat('EEEE').format(day);
              if (availableDays.contains(dayName)) {
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green, // Highlight available days
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}', // Show the day number
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
              return null; // Render normal days
            },
          ),
        ),
        SizedBox(height: 40,),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            "${bundle.translation('selectTimeslot')}",
            style: TextStyle(fontSize: bundle.currentLanguage == 'EN' ? 36:22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10,),
        // Dropdown for Available Slots
        if (availableSlots.isNotEmpty)
          DropdownButton<Map<String, dynamic>>(
            value: selectedSlot,
            items: availableSlots.map((slot) {
              return DropdownMenuItem(
                value: slot,
                child: Text(slot['time']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSlot = value;
              });
              print("Selected Slot: ${selectedSlot!['time']}");
            },
          )
        else
          Text("${bundle.translation('noTimeslots')}"),


        SizedBox(height: 40,),

        // Book Appointment Button
        ElevatedButton(
          onPressed: (selectedSlot != null &&
              selectedDate != null &&
              _selectedAddress != null &&
              selectedDoctor != null &&
              currentUser != null)
              ? () async {
            try {
              String selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
              String selectedTime = selectedSlot!['time'];

              // Check if the slot is already taken
              bool slotTaken = await isSlotTaken(selectedDoctor!['name'], selectedDateStr, selectedTime);

              if (slotTaken) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("${bundle.translation('slotTaken')}"),
                    content: Text("${bundle.translation('slotNotAvailable')}"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("OK"),
                      ),
                    ],
                  ),
                );
              } else {
                // Proceed with booking if the slot is available
                _db.addAppointment(
                  Appointment(
                    email: currentUser!.email,
                    date: selectedDateStr,
                    time: selectedTime,
                    location: _selectedAddress!,
                    doctor: selectedDoctor!['name'],
                    notifyBy: _notifyBy ?? "default",
                  ),
                );

                // Mark slot as occupied
                markSlotAsOccupied(selectedSchedulePath!, selectedDate!, selectedTime);

                final notificationTitle = bundle.translation('hospitalAppointment');
                final notificationMessage = bundle.translation('appointmentNotificationMessage')
                    .replaceAll('{date}', selectedDateStr)
                    .replaceAll('{time}', selectedTime)
                    .replaceAll('{address}', _selectedAddress.toString());
                NotificationService().showAppointmentNotification(
                    title: notificationTitle,
                    message: notificationMessage);
                // Navigate to main screen or show success message
                Navigator.pushNamed(context, '/main');
              }
            } catch (e) {
              print("Error booking appointment: $e");
            }
          }
              : null,
          child: Text("${bundle.translation('book')}"),
        ),
      ],
    );
  }}