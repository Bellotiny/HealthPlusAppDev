import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'AppointmentDatabase.dart';
import 'SettingsControl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final DatabaseAccess _db = DatabaseAccess();
  int _selectedNavItem = 0;
  User? currentUser;
  String? _notifyBy;
  TextEditingController addressController =TextEditingController();
  TextEditingController provinceController =TextEditingController();
  int currentBookingIndex = 0;

  List<String> provinces = ["Alberta", "British Columbia", "Manitoba", "New Brunswick", "Newfoundland and Labrador", "Northwest Territories",
                      "Nova Scotia", "Nunavut", "Ontario", "Prince Edward Island", "Québec", "Saskatchewan", "Yukon"];
  String? selectedProvince;

  List<String> doctors = ["Dr. Peter Griffin", "Dr. Megan Fox", "Dr. Freddy Fasbear", "Dr. Bitton Makitten"];
  String? selectedDoctor;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

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
                // Show the Material Time Picker
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime != null) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                }
              }
            },
            child: picker == 'date' ? Text("${bundle.translation('pickDate')}") : Text("${bundle.translation('pickTime')}"),
          ),
      ],
    );
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedNavItem = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    currentUser = Provider.of<DatabaseAccess>(context).currentUser;
    final bundle = Provider.of<Localization>(context);

    Widget? columnToDisplay(){
      switch(currentBookingIndex){
        case 0:
          return buildLocation(context, bundle);
          break;
        case 1:
          return buildDateTime(context, bundle);
          break;
        case 2:
          return buildDoctor(context, bundle);
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
                onPressed: (){},
                child: Text('${bundle.translation('pickLocation')}')
            )
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
                onPressed: (){},
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
                DropdownButton<String>(
                  value: selectedDoctor,
                  onChanged: (String? doctor) {
                    setState(() {
                      selectedDoctor = doctor;
                    });
                  },
                  items: doctors.map((String doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor,
                      child: Text(doctor),
                    );
                  }).toList(),
                  hint: Text(
                    '${bundle.translation('departmentTextField')}', // Hint text
                    style: TextStyle(color: Colors.grey), // Style for the hint text
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
                        doctor: selectedDoctor,
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

