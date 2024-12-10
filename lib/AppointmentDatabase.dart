import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'Localization.dart';

class DatabaseAccess with ChangeNotifier {
  static final DatabaseAccess _instance = DatabaseAccess._internal();
  Localization bundle = Localization();
  User? _currentUser;
  String? _password;
  CollectionReference users = FirebaseFirestore.instance.collection('Users');
  CollectionReference appointment = FirebaseFirestore.instance.collection(
      'Appointments');
  CollectionReference doctors = FirebaseFirestore.instance.collection('Doctors');

  String? verificationId;

  factory DatabaseAccess() {
    return _instance;
  }

  DatabaseAccess._internal();

  User? get currentUser => _currentUser;

  String get password => password;

  Future<bool> login(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    User? user = await getUser(email);

    if (user == null) {
      // Email was not found in the database
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(
          content: Text('${bundle.translation('incorrectEmail')}!'),
          duration: Duration(seconds: 2),
        ),
      );
      _currentUser = null;
      await prefs.remove('userEmail');
      return false;
    } else {
      // Check if the password matches
      try{
        auth.UserCredential userCredential = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user.email,
          password: password,
        );

        if(userCredential != null){
          print('Logged in as: ${user.firstName} ${user.lastName}');
          _currentUser = user;
          await prefs.setString('userEmail', user.email);
          notifyListeners();
          print(currentUser.toString());
          sendEmailVerification();
          if(password != _currentUser?.password){
            updatePassword(email, password);
          }
          return true;
        }else {
          print("No user logged in Firebase.");
          return false;
        }
      }catch (e) {
        print('${bundle.translation('loginFailed')}: $e');
        return false;
      }
      }
    return false;
  }

  void Function(User?)? callback = (User? user) {
    if (user != null) {
      print("User is logged in: ${user.email}");
    } else {
      print("No user is logged in.");
    }
  };

  Future<void> sendEmailVerification() async {
    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        print("Verification email sent to ${user.email}");
      } else {
        print("No user is logged in to send email verification.");
      }
    } catch (e) {
      print("Error sending email verification: $e");
    }
  }

  Future<bool> isEmailVerified() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("No user is logged in.");
        return false;
      }

      await currentUser.reload();
      final isVerified = currentUser.emailVerified;

      print("Email verification status after reload: $isVerified");
      return isVerified;
    } catch (e) {
      print("Error checking email verification: $e");
      return false;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUser = null;
    await prefs.remove(
        'userEmail');
    notifyListeners();
    if(_currentUser == null){
      print('You Have Successfully Logged Out!!!!!');
    } else{
      print('You Have Failed to Log Out!!!!!');
    }
  }

  // Load the saved user
  Future<bool> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString(
        'userEmail'); // Retrieve the stored user ID


    if (userEmail != null && getUser(userEmail) != null) {
      _currentUser = await getUser(userEmail);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("Password reset email sent.");
    } catch (e) {
      print("Error sending password reset email: $e");
    }
  }

  Future<void> updatePassword(String email, String newPassword) async {
    QuerySnapshot snapshot = await users
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;

      await users.doc(doc.id).update({
        'password': newPassword,
      });
    }
    print("Password updated successfully.");
  }

  Future<void> addUser(User newUser) async{
    try{
      if (newUser.email != null && newUser.password != null) {
        // Create a new user with email and password using Firebase Authentication
        auth.UserCredential userCredential = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: newUser.email,
          password: newUser.password,
        );
        if(userCredential != null){
          return users
              .add({
            'firstName': '${newUser.firstName}',
            'lastName': '${newUser.lastName}',
            'email': '${newUser.email}',
            'password': '${newUser.password}',
            'age': '${newUser.age}',
            'gender': '${newUser.gender}',
            'phoneNumber': '${newUser.phoneNumber}',
            'authentifyBy': '${newUser.authentifyBy}'
          })
              .then((value) => print('A new user was added'))
              .catchError((error) => print('Failed to add the user to Firestore'));
        }
      }
    }catch (e) {
      print('Error creating user: $e');
    }
  }

  Future<User?> getUser(String email) async {
    QuerySnapshot snapshot = await users
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      _password = doc['password'];

      return User(
        id: doc.id,
        firstName: doc['firstName'] ?? '',
        lastName: doc['lastName'] ?? '',
        email: doc['email'] ?? '',
        password: doc['password'] ?? '',
        age: int.parse(doc['age']) ?? 0,
        gender: doc['gender'] ?? '',
        phoneNumber: doc['phoneNumber'] ?? '',
        authentifyBy: doc['authentifyBy'] ?? '',
      );
    }
    return null;
  }


  Future<void> updateUser(String email, User user) async {
    QuerySnapshot snapshot = await users
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Get the first matching document
      var doc = snapshot.docs.first;

      // Update the password in Firestore
      await users
          .doc(doc.id)
          .update({
            'firstName': '${user.firstName}',
            'lastName': '${user.lastName}',
            'age': '${user.age}',
            'gender': '${user.gender}',
            'phoneNumber': '${user.phoneNumber}',
      })
          .then((value) => print('user updated'))
          .catchError((error) => print('Failed to update the user to Firestore'));
    }
  }

  Future<void> deleteUser(String id) async {
    await users
        .doc(id)
        .delete()
        .then((value) => print('users deleted'))
        .catchError((error) =>
        print('Failed to delete the users in Firestore'));
  }

  Future<Doctor?> getDoctor(String doctorId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Doctors')
          .doc(doctorId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Handle the schedule field if it's a DocumentReference
        if (data['schedule'] is DocumentReference) {
          DocumentReference scheduleRef = data['schedule'];
          DocumentSnapshot scheduleDoc = await scheduleRef.get();

          // Merge the fetched schedule data with the doctor data
          if (scheduleDoc.exists) {
            data['schedule'] = scheduleDoc.data();
          } else {
            print('Schedule for Doctor ID $doctorId not found.');
          }
        }

        print('${Doctor.fromMap(data).toString()} was found');
        return Doctor.fromMap(data);
      } else {
        print('Doctor with ID $doctorId not found.');
        return null;
      }
    } catch (e) {
      print('Error fetching doctor data: $e');
      return null;
    }
  }

  Future<List<Doctor>?> getAllDoctors() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Doctors')
          .get();

      List<Doctor> doctors = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        if (data['schedule'] is DocumentReference) {
          DocumentReference scheduleRef = data['schedule'];
          DocumentSnapshot scheduleDoc = await scheduleRef.get();

          if (scheduleDoc.exists) {
            print('Schedule for Doctor ID ${doc.id}');
            data['schedule'] = scheduleDoc.data();
          } else {
            print('Schedule for Doctor ID ${doc.id} not found.');
          }
        }

        doctors.add(Doctor.fromMap(data));
      }

      return doctors;
    } catch (e) {
      print('Error fetching doctors: $e');
      return [];
    }
  }

  Future<List<Schedule>?> getDoctorSchedule(String doctorId) async {
    Doctor? doctor = await getDoctor(doctorId);

    if (doctor != null) {
      return doctor.schedule;
    }
    return [];
  }

  Future<void> updateDoctorTimeSlot(
      String doctorId, String day, String timeSlot, String newStatus) async {
    try {
      Doctor? doctor = await getDoctor(doctorId);

      if (doctor != null) {
        Schedule? daySchedule;
        for (var schedule in doctor.schedule) {
          if (schedule.day == day) {
            daySchedule = schedule;
            break;
          }
        }

        if (daySchedule != null) {
          // Update the time slot status
          for (var slot in daySchedule.timeSlots) {
            if (slot.timeRange == timeSlot) {
              slot.status = newStatus;
              break;
            }
          }

          // Convert the schedule back to a Map and update Firestore
          List<Map<String, dynamic>> updatedSchedule = doctor.schedule
              .map((schedule) => schedule.toMap())
              .toList();

          await FirebaseFirestore.instance
              .collection('Doctors')
              .doc(doctorId)
              .update({
            'schedule': updatedSchedule,
          });

          print("Time slot status updated successfully for Doctor ID: $doctorId");
        } else {
          print("Day schedule not found for $day.");
        }
      } else {
        print("Doctor not found with ID: $doctorId.");
      }
    } catch (e) {
      print("Error updating time slot: $e");
    }
  }

  Future<List<String>> getAvailableTimes(String? doctorId, DateTime selectedDate) async {
    int weekday = selectedDate.weekday;

    // Fetch the doctor object
    Doctor? doctor = await getDoctor(doctorId!);
    if (doctor == null) {
      print("Doctor not found.");
      return [];
    }

    String dayOfWeek = _getDayStringFromWeekday(weekday);
    print("Fetching available times for: $dayOfWeek");

    for (var schedule in doctor.schedule) {
      if (schedule.day == dayOfWeek) {
        if (schedule.timeSlots != null) {
          List<String> availableTimes = schedule.timeSlots
              .where((slot) => slot.status == 'available')
              .map<String>((slot) => slot.timeRange)
              .toList();

          print("Available times for $dayOfWeek: $availableTimes");
          return availableTimes;
        } else {
          print("No time slots available for $dayOfWeek.");
          return [];
        }
      }
    }

    print("No schedule found for $dayOfWeek.");
    return [];
  }



  String _getDayStringFromWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }


  Future<void> addAppointment(Appointment apt) {
    return appointment
        .add({
      'email': '${currentUser?.email}',
      'date': '${apt.date}',
      'time': '${apt.time}',
      'location': '${apt.location}',
      'doctor': '${apt.doctor}',
      'notifyBy': '${apt.notifyBy}'
    })
        .then((value) => print('appointment added'))
        .catchError((error) =>
        print('Failed to add the appointment to Firestore'));
  }

  Future<List<Appointment>> getCurrentAppointments() async {
    DateTime now = DateTime.now();
    String today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now
        .day.toString().padLeft(2, '0')}';

    QuerySnapshot snapshot = await appointment
        .where('email', isEqualTo: currentUser?.email)
        .where('date', isGreaterThanOrEqualTo: today)
        .orderBy('date')
        .get();

    List<Appointment> appointments = [];

    if (snapshot.docs.isNotEmpty) {
      DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      DateFormat dayFormat = DateFormat('MMMM d, yyyy');

      appointments = snapshot.docs.map((doc) {
        String dateString = doc['date'] ?? '';
        String timeString = doc['time'] ?? '';

        String formattedDate;
        try {
          DateTime dateTime = dateFormat.parse(dateString);
          formattedDate =
              dateFormat.format(dateTime);
        } catch (e) {
          print('Error trying to parse date: $e');
          return null;
        }

        DateTime appointmentDateTime;
        try {
          appointmentDateTime =
              dateFormat.parse(formattedDate + ' ' + timeString);
        } catch (e) {
          print('Error parsing date and time: $e');
          return null;
        }

        if (appointmentDateTime.isAfter(now) ||
            appointmentDateTime.isAtSameMomentAs(now)) {
          DateTime newDate = dateFormat.parse(formattedDate);
          String finalDate = dayFormat.format(newDate);
          String finalTime = timeString;
          return Appointment(
            id: doc.id,
            email: doc['email'] ?? '',
            date: finalDate,
            // Use the formatted date without the time
            time: finalTime,
            location: doc['location'] ?? '',
            doctor: doc['doctor'] ?? '',
          );
        }
        return null;
      }).whereType<Appointment>().toList();
    }

    return appointments;
  }

  Future<List<Appointment>> getHistory() async {
    DateTime now = DateTime.now();
    String today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now
        .day.toString().padLeft(2, '0')}';

    QuerySnapshot snapshot = await appointment
        .where('email', isEqualTo: currentUser?.email)
        .get();

    List<Appointment> appointments = [];

    if (snapshot.docs.isNotEmpty) {
      DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      DateFormat dayFormat = DateFormat('EEEE, MMMM d, yyyy');

      appointments = snapshot.docs.map((doc) {
        String dateString = doc['date'] ?? '';
        String timeString = doc['time'] ?? '';

        DateTime newDate = dateFormat.parse(dateString);
        String finalDate = dayFormat.format(newDate);
        String finalTime = timeString;

        return Appointment(
          id: doc.id,
          email: doc['email'] ?? '',
          date: finalDate,
          time: finalTime,
          location: doc['location'] ?? '',
          doctor: doc['doctor'] ?? '',
        );
      }).whereType<Appointment>().toList();
    }

    return appointments;
  }

  Future<List<List<Appointment>>> getAppointmentsGroupedByWeek() async {
    List<Appointment> appointments = await getHistory(); // Assuming getHistory fetches the appointments

    int getWeekNumber(DateTime date) {
      var formatter = DateFormat('w');
      return int.parse(formatter.format(date));
    }

    Map<int, List<Appointment>> weeklyGroups = {};
    for (Appointment appointment in appointments) {
      DateTime date = DateTime.parse(appointment.date);
      int weekNumber = getWeekNumber(date);

      if (weeklyGroups.containsKey(weekNumber)) {
        weeklyGroups[weekNumber]!.add(appointment);
      } else {
        weeklyGroups[weekNumber] = [appointment];
      }
    }

    return weeklyGroups.values.toList();
  }


  Future<void> updateAppointment(String id, Appointment apt) async {
    await appointment
        .doc(id)
        .update({
      'date': '${apt.date}',
      'time': '${apt.time}',
      'location': '${apt.location}',
      'doctor': '${apt.doctor}',
      'notifyBy': '${apt.notifyBy}'
    })
        .then((value) => print('appointment updated'))
        .catchError((error) =>
        print('Failed to update the appointment to Firestore'));
  }

  Future<void> deleteAppointment(String id) async {
    await appointment
        .doc(id)
        .delete()
        .then((value) => print('appointment deleted'))
        .catchError((error) =>
        print('Failed to delete the appointment in Firestore'));
  }
}

class User {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final int age;
  final String gender;
  final String phoneNumber;
  String? authentifyBy;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.age,
    required this.gender,
    required this.phoneNumber,
    this.authentifyBy='email',
  });

  User.fromMap(Map<String, dynamic> result)
      : id = result['id'],
        firstName = result['firstName'],
        lastName = result['lastName'],
        email = result['email'],
        password = result['password'],
        age = result['age'],
        gender = result['gender'],
        phoneNumber = result['phoneNumber'],
        authentifyBy = result['authentifyBy'];

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'authentifyBy': authentifyBy,
    };
  }

  @override
  String toString() {
    return 'User{firstName: $firstName, lastName: $lastName, email: $email, password: $password, age: $age, gender: $gender, phoneNumber: $phoneNumber}';
  }
}

class Appointment {
  final String? id;
  final String email;
  final String date;
  final String time;
  final String location;
  final String? doctor;
  final String? notifyBy;

  Appointment({
    this.id,
    required this.email,
    required this.date,
    required this.time,
    required this.location,
    this.doctor,
    this.notifyBy = "email",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'date': date,
      'time': time,
      'location': location,
      'doctor': doctor,
      'notifyBy': notifyBy,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      email: map['email'],
      date: map['date'],
      time: map['time'],
      location: map['location'],
      doctor: map['doctor'],
      notifyBy: map['notifyBy'],
    );
  }

  @override
  String toString() {
    return 'Appointment{id: $id, email: $email, date: $date, time: $time, location: $location, doctor: $doctor}';
  }
}

class Doctor {
  String? id;
  final String name;
  final String specialty;
  final List<Schedule> schedule;

  Doctor({
    this.id,
    required this.name,
    required this.specialty,
    required this.schedule,
  });

  factory Doctor.fromMap(Map<String, dynamic> data) {
    List<Schedule> scheduleList = [];

    if (data['schedule'] != null) {
      Map<String, dynamic> scheduleData = data['schedule'] as Map<String, dynamic>;

      scheduleData.forEach((day, timeSlots) {
        scheduleList.add(Schedule.fromMap({
          'day': day,
          'timeSlots': timeSlots,
        }));
      });
    }

    return Doctor(
      id: data['id'],
      name: data['doctor'],
      specialty: data['specialty'],
      schedule: scheduleList,
    );
  }

  @override
  String toString() {
    return 'Doctor{id: $id, name: $name, specialty: $specialty, schedule: $schedule}';
  }
}

class Schedule {
  final String day;
  final List<Slot> timeSlots;

  Schedule({
    required this.day,
    required this.timeSlots,
  });

  factory Schedule.fromMap(Map<String, dynamic> data) {
    List<Slot> timeSlots = [];

    if (data['timeSlots'] != null) {
      // If timeSlots is a map, convert it into a list of Slot objects
      if (data['timeSlots'] is Map) {
        Map<String, dynamic> timeSlotsData = data['timeSlots'] as Map<String, dynamic>;
        timeSlotsData.forEach((key, value) {
          timeSlots.add(Slot.fromMap(value));
        });
      } else if (data['timeSlots'] is List) {
        timeSlots = (data['timeSlots'] as List).map((slotData) => Slot.fromMap(slotData)).toList();
      } else {
        print('Warning: TimeSlots data is not in a recognized format.');
      }
    }

    return Schedule(
      day: data['day'],
      timeSlots: timeSlots,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'Schedule{day: $day, timeSlots: $timeSlots}';
  }
}


class Slot {
  final String timeRange;
  String status;

  Slot({
    required this.timeRange,
    required this.status,
  });

  factory Slot.fromMap(Map<String, dynamic> data) {
    return Slot(
      timeRange: data['time'] ?? '',
      status: data['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': timeRange,
      'status': status,
    };
  }


}