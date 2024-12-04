import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'AppointmentDatabase.dart';
import 'SettingsControl.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  final DatabaseAccess _db = DatabaseAccess();
  int _selectedNavItem = 3;
  User? currentUser;

  void _onItemTapped(int index) {
    setState(() {
      _selectedNavItem = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    currentUser = Provider.of<DatabaseAccess>(context).currentUser;
    final bundle = Provider.of<Localization>(context);

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
            padding: EdgeInsets.all(20.0),
            child: FutureBuilder<List<Appointment>>(
              future: _db.getCurrentAppointments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 60,),
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
                              '${bundle.translation('viewTitle')}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: bundle.currentLanguage == 'EN' ? 52:46,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60,),
                        Text('${bundle.translation('noUpcoming')}'),
                      ],
                    ),
                  );
                } else {
                  final appointments = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            '${bundle.translation('viewTitle')}',
                            style: TextStyle(
                              fontSize: bundle.currentLanguage == 'EN' ? 24:20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text('${bundle.translation('upcoming')}')],
                      ),
                      SizedBox(height: 30,),
                      Container(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: ListView.builder(
                          shrinkWrap: true,
                          // Makes the ListView take only as much space as needed
                          physics: NeverScrollableScrollPhysics(),
                          // Disables scrolling for the ListView
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              // Adds space between each item
                              padding: EdgeInsets.all(12.0),
                              // Adds padding inside the border
                              decoration: BoxDecoration(
                                color: Provider.of<ThemeControl>(context).themeMode == 1
                                    ? Colors.black
                                    : Colors.white,
                                border: Border.all(
                                  color: Colors.grey, // Border color
                                  width: 1.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(
                                    8.0), // Rounded corners
                              ),
                              child: Column(
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
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedNavItem: _selectedNavItem,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
