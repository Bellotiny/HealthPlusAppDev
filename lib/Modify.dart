import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'AppointmentDatabase.dart';
import 'SettingsControl.dart';
import 'package:intl/intl.dart';

class ModifyScreen extends StatefulWidget {
  final Appointment appointment;

  const ModifyScreen({Key? key, required this.appointment}) : super(key: key);

  @override
  State<ModifyScreen> createState() => _ModifyScreenState();
}

class _ModifyScreenState extends State<ModifyScreen> {
  int currentStep = 0;
  int _selectedNavItem = 1;
  late TextEditingController locationController;
  late TextEditingController doctorController;
  List<String> doctors = ["Dr. Peter Griffin", "Dr. Megan Fox", "Dr. Freddy Fasbear", "Dr. Bitton Makitten"];
  String? selectedDoctor;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current appointment data
    locationController = TextEditingController(text: widget.appointment.location);
    doctorController = TextEditingController(text: widget.appointment.doctor ?? '');

    // Correct the date format to 'yyyy-MM-dd' for parsing
    final dateFormat = DateFormat('yyyy-MM-dd');
    try {
      selectedDate = dateFormat.parse(widget.appointment.date);
    } catch (e) {
      print('Error parsing date: $e');
      selectedDate = DateTime.now(); // Fallback to current date if parsing fails
    }

    // Parse appointment time
    try {
      final timeParts = widget.appointment.time.split(":");
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } catch (e) {
      print('Error parsing time: $e');
      selectedTime = TimeOfDay.now(); // Fallback to current time if parsing fails
    }
  }


  @override
  void dispose() {
    locationController.dispose();
    doctorController.dispose();
    super.dispose();
  }

  Widget _buildLocationStep(Localization bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 330,
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
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
              '${bundle.translation('location')}',
              style: TextStyle(
                fontSize: bundle.currentLanguage == 'EN' ? 24:20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 50,),
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
        SizedBox(height: 50,),
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
        const SizedBox(height: 20),
        Text(
          bundle.translation('modifyLocation'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: bundle.translation('location'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeStep(Localization bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 370,
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
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
              '${bundle.translation('date')} & ${bundle.translation('time')} ',
              style: TextStyle(
                fontSize: bundle.currentLanguage == 'EN' ? 24:20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          bundle.translation('modifyDatetime'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Blue background
            foregroundColor: Colors.white, // White text
          ),
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                selectedDate = pickedDate;
              });
            }
          },
          child: Text(
            selectedDate != null
                ? '${bundle.translation('selectedDate')}: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'
                : bundle.translation('pickDate'),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Blue background
            foregroundColor: Colors.white, // White text
          ),
          onPressed: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: selectedTime ?? TimeOfDay.now(),
            );
            if (pickedTime != null) {
              setState(() {
                selectedTime = pickedTime;
              });
            }
          },
          child: Text(
            selectedTime != null
                ? '${bundle.translation('selectedTime')} ${selectedTime!.format(context)}'
                : bundle.translation('pickTime'),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorStep(Localization bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 330,
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
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
              '${bundle.translation('doctor')} ',
              style: TextStyle(
                fontSize: bundle.currentLanguage == 'EN' ? 24:20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          bundle.translation('modifyDoctor'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: selectedDoctor ?? widget.appointment.doctor,
          decoration: InputDecoration(
            labelText: bundle.translation('doctor'),
            border: const OutlineInputBorder(),
          ),
          items: doctors.map((doctor) {
            return DropdownMenuItem<String>(
              value: doctor,
              child: Text(doctor),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedDoctor = newValue;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);

    void saveChanges() async {
      try {
        final updatedAppointment = Appointment(
          email: widget.appointment.email,
          date: selectedDate?.toIso8601String().split('T')[0] ?? '',
          time:
          '${selectedTime?.hour.toString().padLeft(2, '0')}:${selectedTime?.minute.toString().padLeft(2, '0')}',
          location: locationController.text,
          doctor: selectedDoctor,
        );

        await Provider.of<DatabaseAccess>(context, listen: false)
            .updateAppointment(widget.appointment.id!, updatedAppointment);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bundle.translation('modifySuccessful')}')),
        );

        Navigator.pushNamed(context, '/main');
      } catch (e) {
        print('Error saving changes: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bundle.translation('modifyFailed')}')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Health +', style: const TextStyle(fontSize: 24)),
        leading: IconButton(
          icon: const Icon(Icons.settings, size: 30), // Left icon
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, size: 30), // Right icon
            onPressed: () {
              Navigator.pushNamed(context, '/account');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IndexedStack(
            index: currentStep,
            children: [
              _buildLocationStep(bundle),
              _buildDateTimeStep(bundle),
              _buildDoctorStep(bundle),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Blue background
                    foregroundColor: Colors.white, // White text
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to ModifyView
                  },
                  child: Text(bundle.translation('cancel')),
                ),
                Row(
                  children: [
                    if (currentStep > 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Blue background
                          foregroundColor: Colors.white, // White text
                        ),
                        onPressed: () {
                          setState(() {
                            currentStep--;
                          });
                        },
                        child: Text(bundle.translation('back')),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Blue background
                        foregroundColor: Colors.white, // White text
                      ),
                      onPressed: () {
                        if (currentStep < 2) {
                          setState(() {
                            currentStep++;
                          });
                        } else {
                          saveChanges();
                        }
                      },
                      child: Text(
                        currentStep < 2
                            ? bundle.translation('next')
                            : bundle.translation('modify'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CustomBottomNavBar(
            selectedNavItem: _selectedNavItem,
            onItemTapped: (index) {
              setState(() {
                _selectedNavItem = index;
              });
            },
          ),
        ],
      ),
    );
  }
}