import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'AppointmentDatabase.dart';
import 'SettingsControl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';


// Add geocoding package for reverse geocoding.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final DatabaseAccess _db = DatabaseAccess();
  TextEditingController addressController = TextEditingController();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  LatLng _initialLocation = LatLng(45.5017, -73.5673);
  int _selectedNavItem = 0;
  User? currentUser;
  String? _notifyBy;
  final String apiKey = "AIzaSyA5SRUdgp80WhwV7sVVwLa1wSbWNPwLQ5g";
  Set<Marker> hospitalMarkers = {};
  final LatLng montrealCoordinates = LatLng(45.5017, -73.5673);

  TextEditingController provinceController =TextEditingController();
  int currentBookingIndex = 0;

  List<String> provinces = ["Alberta", "British Columbia", "Manitoba", "New Brunswick", "Newfoundland and Labrador", "Northwest Territories",
    "Nova Scotia", "Nunavut", "Ontario", "Prince Edward Island", "Québec", "Saskatchewan", "Yukon"];
  String? selectedProvince;

  List<Doctor>? doctors;
  Doctor? selectedDoctor;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    requestLocationPermission();
    _fetchCurrentLocation();

  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _initialLocation = LatLng(position.latitude, position.longitude);
      });

      // Fetch hospitals after updating the location
      await _fetchHospitals();
    } catch (e) {
      print("Error fetching location: $e");
    }
  }


  LatLng? _getNearestMarker() {
    if (hospitalMarkers.isEmpty) return null;

    Marker? nearestMarker;
    double minDistance = double.infinity;

    for (Marker marker in hospitalMarkers) {
      double distance = Geolocator.distanceBetween(
        _initialLocation.latitude,
        _initialLocation.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestMarker = marker;
      }
    }

    return nearestMarker?.position;
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      print("Location permission granted");
      await _fetchCurrentLocation();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      print("Location permission denied");
      // Show a dialog or redirect user to settings
      openAppSettings();
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
              snippet: hospital['vicinity'], // Address of the hospital
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          );
        }).toSet();

        setState(() {
          hospitalMarkers = markers;
        });

        print("Markers fetched: ${hospitalMarkers.length}");
      } else {
        print("Error fetching hospitals: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching hospitals: $e");
    }
  }


  void _openGoogleMap(BuildContext context) {
    if (_initialLocation == null) {
      // Show a loading spinner while waiting for the location
      showDialog(
        context: context,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
    } else {
      // Open the map once the location is fetched
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialLocation, // Use updated current location
                zoom: 12,
              ),
              myLocationEnabled: true,
              scrollGesturesEnabled: true,
              markers: hospitalMarkers, // Add hospital markers to the map
              onTap: (LatLng location) async {
                await _getAddressFromCoordinates(location);
                Navigator.pop(context); // Close the modal after selecting a location
              },
            ),
          );
        },
      );
    }
  }
  // Reverse geocode to get the address from coordinates
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
      setState(() {
        addressController.text = "Unable to fetch address: $e";
      });
    }
  }

  Widget buildDateTimePicker(BuildContext context, Localization bundle, String picker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (picker == 'date' && selectedDate != null)
          Text(
            "${bundle.translation('selectedDate')} ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!)}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        if (picker == 'time' && selectedTime != null)
          Text(
            "${bundle.translation('selectedTime')} ${selectedTime!.format(context)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            if (picker == 'date') {
              // Show the Material Date Picker
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000, 1, 1),
                lastDate: DateTime(2100, 12, 31),
              );

              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            } else {
              if (selectedDate != null) {
                String? pickedTime = await showAvailableTimePicker(context, selectedDate!);

                if (pickedTime != null) {
                  setState(() {
                    selectedTime = TimeOfDay(
                        hour: int.parse(pickedTime.split(":")[0]),
                        minute: int.parse(pickedTime.split(":")[1]));
                  });
                }
              }
            }
          },
          child: picker == 'date' ? Text("${bundle.translation('pickDate')}") : Text("${bundle.translation('pickTime')}"),
        ),
      ],
    );
  }


  Future<String?> showAvailableTimePicker(BuildContext context, DateTime selectedDate) async {
    List<String> availableTimes = await _db.getAvailableTimes(selectedDoctor!.id,selectedDate);

    if (availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No available times for this day."),
      ));
      return null;
    }

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Available Time"),
          content: SingleChildScrollView(
            child: Column(
              children: availableTimes.map((time) {
                return ListTile(
                  title: Text(time),
                  onTap: () {
                    Navigator.pop(context, time); // Return the selected time
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedNavItem = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    doctors = _db.getAllDoctors() as List<Doctor>?;
    currentUser = Provider.of<DatabaseAccess>(context).currentUser;
    final bundle = Provider.of<Localization>(context);

    Widget? columnToDisplay(){
      switch(currentBookingIndex){
        case 0:
          return buildLocation(context, bundle);
          break;
        case 1:
          return buildDoctor(context, bundle);
          break;
        case 2:
          return buildDateTime(context, bundle);
          break;
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Health +',style: TextStyle(fontSize: 24),),
        leading: IconButton(
          icon: Icon(Icons.settings,size: 30,), // Left icon
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/settings',
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person,size: 30,), // Right icon
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/account',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: columnToDisplay()
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedNavItem: _selectedNavItem,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Column buildLocation(BuildContext context, Localization bundle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 10,),
        Container(
          width: 300,
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFF529DFF),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent,
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${bundle.translation('scheduleTitle')}',
              style: TextStyle(
                color: Colors.white,
                fontSize: bundle.currentLanguage == 'EN' ? 26:18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 45,),
        Container(
          padding: EdgeInsets.only(left: 40, right: 40),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                backgroundColor: Colors.white54,
              ),
              onPressed: ()=>_openGoogleMap(context),
              child: Text('${bundle.translation('pickLocation')}')
          ),

        ),

        SizedBox(height: 30,),
        Container(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Text('${bundle.translation('or')}',style: TextStyle(fontSize: 24),)
        ),
        SizedBox(height: 30,),
        Container(
            padding: EdgeInsets.only(left: 40, right: 40),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  backgroundColor: Colors.white54,
                ),
                onPressed: () async {
                  LatLng? nearestLocation = _getNearestMarker();
                  if (nearestLocation != null) {
                    await _getAddressFromCoordinates(nearestLocation);
                  }
                },
                child: Text('${bundle.translation('pickNearest')}')
            )
        ),
        SizedBox(height: 40,),
        Container(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "${bundle.translation('address')}", // The label text on top
                hintText: "E.g. 111 rue AppDev, Vanier", // Example text inside the box
                border: OutlineInputBorder(), // Full border around the TextField
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            )
        ),
        SizedBox(height: 40,),
        Container(
          padding: EdgeInsets.only(right: 230),
          child: Text(
            "${bundle.translation('province')}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey, // Border color
                width: 1.0, // Border width
              ),
              borderRadius: BorderRadius.circular(8.0), // Rounded corners
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(width: 50,),
                DropdownButton<String>(
                  value: selectedProvince,
                  onChanged: (String? province) {
                    setState(() {
                      selectedProvince = province;
                    });
                  },
                  items: provinces.map((String province) {
                    return DropdownMenuItem<String>(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  hint: Text(
                    '${bundle.translation('provinceTextField')}', // Hint text
                    style: TextStyle(color: Colors.grey), // Style for the hint text
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20,),
        Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("${bundle.translation('cancel')}"),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      currentBookingIndex = 1;
                    });
                  },
                  child: Text("${bundle.translation('next')}")
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column buildDateTime(BuildContext context, Localization bundle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 10,),
        Container(
          width: 300,
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFF529DFF),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent,
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${bundle.translation('scheduleTitle')}',
              style: TextStyle(
                color: Colors.white,
                fontSize: bundle.currentLanguage == 'EN' ? 26:18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 70,),
        Container(
          child: buildDateTimePicker(context,bundle,'date'),
        ),
        SizedBox(height: 90,),
        Container(
          child: buildDateTimePicker(context,bundle,'time'),
        ),
        SizedBox(height: 100,),
        Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    currentBookingIndex = 0;
                  });
                },
                child: Text("${bundle.translation('back')}"),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      currentBookingIndex = 2;
                    });
                  },
                  child: Text("${bundle.translation('next')}")
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column buildDoctor(BuildContext context, Localization bundle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 10,),
        Container(
          width: 300,
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFF529DFF),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent,
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${bundle.translation('scheduleTitle')}',
              style: TextStyle(
                color: Colors.white,
                fontSize: bundle.currentLanguage == 'EN' ? 26:18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 45,),
        Container(
          padding: EdgeInsets.only(right: 230),
          child: Text(
            "${bundle.translation('department')}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 4),
        SizedBox(height: 8,),
        Padding(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey, // Border color
                width: 1.0, // Border width
              ),
              borderRadius: BorderRadius.circular(8.0), // Rounded corners
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(width: 50,),
                DropdownButton<Doctor>(
                  value: selectedDoctor,
                  onChanged: (Doctor? doctor) {
                    setState(() {
                      selectedDoctor = doctor;
                    });
                  },
                  items: doctors?.map((Doctor doctor) {
                    return DropdownMenuItem<Doctor>(
                      value: doctor,
                      child: Text(doctor.doctor),
                    );
                  }).toList(),
                  hint: Text(
                    '${bundle.translation('departmentTextField')}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 40,),
        Padding(
          padding: EdgeInsets.only(left: 20.0,right: 20.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blueAccent, // Border color
                width: 2, // Border width
              ),
              borderRadius: BorderRadius.circular(12), // Optional: for rounded corners
            ),
            padding: EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(height: 10,),
                Text("${bundle.translation('notification')}"),
                SizedBox(height: 20,),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 90,),
                        Radio<String>(
                          value: "",
                          groupValue: _notifyBy,
                          onChanged: (String? value) {
                            setState(() {
                              _notifyBy = value;
                            });
                          },
                        ),
                        Text("${bundle.translation('email')}"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 90,),
                        Radio<String>(
                          value: "${bundle.translation('phone')}",
                          groupValue: _notifyBy,
                          onChanged: (String? value) {
                            setState(() {
                              _notifyBy = value;
                            });
                          },
                        ),
                        Text("${bundle.translation('phone')}"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Container(
                width: 140, // Specify the width of the button here
                child: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        currentBookingIndex = 1;
                      });
                    },
                    child: Text("${bundle.translation('back')}"),
                  ),
                ),
              ),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: bundle.currentLanguage == 'EN' ? 24:28, vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _db.addAppointment(
                      Appointment(
                        email: currentUser!.email,
                        date: selectedDate.toString(),
                        time: selectedTime.toString(),
                        location: '${addressController.text}, ${selectedProvince}',
                        doctor: selectedDoctor?.doctor,
                        notifyBy: _notifyBy!.isNotEmpty ? _notifyBy : null,
                      )
                  );
                  Navigator.pushNamed(
                    context,
                    '/main',
                  );
                },
                child: Text("${bundle.translation('book')}",style: TextStyle(fontSize: bundle.currentLanguage == 'EN' ? 12:10),)
            ),
          ],
        ),
      ],
    );
  }
}

