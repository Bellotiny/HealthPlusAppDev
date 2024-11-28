import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'AppointmentDatabase.dart';
import 'SettingsControl.dart';
import 'Modify.dart';

class ModifyView extends StatefulWidget {
  const ModifyView({super.key});

  @override
  State<ModifyView> createState() => _ModifyViewState();
}

class _ModifyViewState extends State<ModifyView> {
  int? selectedIndex;
  int _selectedNavItem = 1; // Default to Modify tab
// Selected appointment index
  List<Appointment>? appointments;

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);
    final dbAccess = Provider.of<DatabaseAccess>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Health +',
          style: TextStyle(fontSize: 24),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.settings,
            size: 30,
          ), // Left icon
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/settings',
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.person,
              size: 30,
            ), // Right icon
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/account',
              );
            },
          ),
        ],
      ),
      body: _buildAppointmentList(context, dbAccess, bundle),
    );
  }

  Widget _buildAppointmentList(
      BuildContext context, DatabaseAccess dbAccess, Localization bundle) {
    return FutureBuilder<List<Appointment>>(
      future: dbAccess.getCurrentAppointments(),
      // Fetch appointments from Firestore
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(bundle.translation('no_appointments')));
        } else {
          appointments = snapshot.data!;
          return Column(
            children: [
              SizedBox(height: 20),
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
                    '${bundle.translation('modify')}',
                    style: TextStyle(
                      fontSize: bundle.currentLanguage == 'EN' ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: appointments!.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments![index];
                    return Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        // Adds padding inside the border
                        decoration: BoxDecoration(
                          color: Provider.of<ThemeControl>(context).themeMode == 1
                              ? Colors.black
                              : Colors.white,
                          border: Border.all(
                            color: Colors.grey, // Border color
                            width: 1.0, // Border width
                          ),
                          borderRadius:
                          BorderRadius.circular(8.0), // Rounded corners
                        ),
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${bundle.translation('date')}: ${appointment.date}'),
                              Text(
                                  '${bundle.translation('time')}: ${appointment.time}'),
                              Text(
                                  '${bundle.translation('location')}: ${appointment.location}'),
                              Text(
                                  '${bundle.translation('doctor')}: ${appointment.doctor}'),
                            ],
                          ),
                          leading: Radio<int>(
                            value: index,
                            groupValue: selectedIndex,
                            onChanged: (int? value) {
                              setState(() {
                                selectedIndex = value;
                              });
                            },
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await dbAccess.deleteAppointment(appointment.id!);
                              setState(() {}); // Refresh the list after deletion
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(bundle
                                        .translation('appointmentDeleted'))),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: (selectedIndex == null)
                      ? null
                      : () {
                          final selectedAppointment =
                              appointments![selectedIndex!];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModifyScreen(
                                  appointment: selectedAppointment),
                            ),
                          ).then((_) {
                            setState(() {}); // Refresh after returning
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 50), // Full-width button
                  ),
                  child: Text(bundle.translation('modify')),
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
          );
        }
      },
    );
  }
}
