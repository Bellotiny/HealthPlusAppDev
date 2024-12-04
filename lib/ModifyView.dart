import 'package:flutter/material.dart';
import 'Modify.dart';
import 'AppointmentDatabase.dart';
import 'Localization.dart';
import 'package:provider/provider.dart';
import 'SettingsControl.dart';

class ModifyView extends StatefulWidget {
  @override
  _ModifyViewState createState() => _ModifyViewState();
}

class _ModifyViewState extends State<ModifyView> {
  int? selectedIndex;
  List<Appointment>? appointments;
  final DatabaseAccess _db = DatabaseAccess();
  int _selectedNavItem = 2;
  User? currentUser;

  void _onItemTapped(int index) {
    setState(() {
      _selectedNavItem = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAppointments(); // Fetch appointments when the view initializes
  }

  void _fetchAppointments() async {
    final fetchedAppointments = await _db.getCurrentAppointments();
    setState(() {
      appointments = fetchedAppointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Health +', style: TextStyle(fontSize: 24)),
        leading: IconButton(
          icon: Icon(Icons.settings, size: 30), // Left icon
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/settings',
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, size: 30), // Right icon
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/account',
              );
            },
          ),
        ],
      ),
      body: appointments == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 30,),

          Container(
            width: 330,
            height: 80,
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
                '${bundle.translation('modify')}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: bundle.currentLanguage == 'EN' ? 52:46,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 30,),
          Expanded(
            child: ListView.builder(
              itemCount: appointments?.length ?? 0,
              itemBuilder: (context, index) {
                final appointment = appointments![index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Provider.of<ThemeControl>(context).themeMode == 1
                        ? Colors.black
                        : Colors.white,
                    border: Border.all(color: Colors.grey, width: 1.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${bundle.translation('date')}: ${appointment.date}'),
                        Text('${bundle.translation('time')}: ${appointment.time}'),
                        Text('${bundle.translation('location')}: ${appointment.location}'),
                        Text('${bundle.translation('doctor')}: ${appointment.doctor}'),
                      ],
                    ),
                    leading: Radio<int>(
                      value: index,
                      groupValue: selectedIndex,
                      onChanged: (value) {
                        setState(() {
                          selectedIndex = value;
                        });
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _confirmDelete(context, appointment);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: selectedIndex == null
                  ? null
                  : () {
                final selectedAppointment = appointments![selectedIndex!];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ModifyScreen(appointment: selectedAppointment),
                  ),
                ).then((value) {
                  // Refresh appointments after returning from ModifyScreen
                  _fetchAppointments();
                });
              },
              child: Text(bundle.translation('modify')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedNavItem: _selectedNavItem,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Appointment appointment) {
    final bundle = Provider.of<Localization>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bundle.translation('confirmDelete')),
        content: Text(bundle.translation('deleteConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(bundle.translation('cancel')),
          ),
          TextButton(
            onPressed: () {
              _deleteAppointment(appointment);
              Navigator.pop(context);
            },
            child: Text(bundle.translation('delete')),
          ),
        ],
      ),
    );
  }

  void _deleteAppointment(Appointment appointment) async {
    await _db.deleteAppointment(appointment.id!);
    setState(() {
      appointments?.remove(appointment);
    });
    NotificationService().showCancellationNotification(
        date: appointment.date, time: appointment.time, address: appointment.location);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Appointment deleted successfully.')),
    );
  }
}