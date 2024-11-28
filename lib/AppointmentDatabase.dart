import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseAccess with ChangeNotifier {
  static final DatabaseAccess _instance = DatabaseAccess._internal();
  User? _currentUser;
  String? _password;
  CollectionReference users = FirebaseFirestore.instance.collection('Users');
  CollectionReference appointment = FirebaseFirestore.instance.collection(
      'Appointments');
  String? verificationId;

  factory DatabaseAccess() {
    return _instance;
  }

  DatabaseAccess._internal();

  User? get currentUser => _currentUser;

  String get password => password;

  Future<void> login(User? user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (user == null) {
      _currentUser = null;
      await prefs.remove('userEmail'); // Clear the saved email if logging out
    } else {
      _currentUser = user;
      await prefs.setString('userEmail', user.email); // Save the user's email
      notifyListeners(); // Notify listeners to update the UI
      if (currentUser?.authentifyBy == "email") {
        sendEmailVerification();
      } else {
        sendPhoneVerification();
      }
    }
  }

  Future<void> sendPhoneVerification() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: currentUser?.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieve or instant verification
          await FirebaseAuth.instance.signInWithCredential(credential);
          print("Phone verification completed successfully.");
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Phone verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId = verificationId;
          print("Code sent to ${currentUser?.phoneNumber}");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      print("Error sending phone verification: $e");
    }
  }

  Future<bool> verifyPhoneCode(String code) async {
    if (verificationId == null) {
      print("Verification ID is null. Please request a new code.");
      return false;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: code.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      print("Phone code verified successfully.");
      return true; // Verification succeeded
    } catch (e) {
      print("Invalid verification code: $e");
      return false; // Verification failed
    }
  }


  Future<void> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        print("Verification email sent to ${currentUser?.email}");
      } else {
        print("No user is logged in to send email verification.");
      }
    } catch (e) {
      print("Error sending email verification: $e");
    }
  }

  Future<bool> isEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentUser = null; // Clear the current user in memory
    await prefs.remove(
        'userEmail'); // Forget the user email in SharedPreferences
    notifyListeners(); // Notify listeners to update the UI
  }

  // Load the saved user
  Future<bool> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString(
        'userEmail'); // Retrieve the stored user ID


    if (userEmail != null && getUser(userEmail) != null) {
      // Fetch the user data from your SQL database using the userId
      _currentUser = await getUser(userEmail);
      notifyListeners(); // Update the UI
      return true;
    }
    return false;
  }

  Future<void> updatePassword(String email, String newPassword) async {
    QuerySnapshot snapshot = await users
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Get the first matching document
      var doc = snapshot.docs.first;

      // Update the password in Firestore
      await users.doc(doc.id).update({
        'password': newPassword,
      });
    }
    print("Password updated successfully.");
  }

  Future<void> addUser(User user) {
    return users
        .add({
      'firstName': '${user.firstName}',
      'lastName': '${user.lastName}',
      'email': '${user.email}',
      'password': '${user.password}',
      'age': '${user.age}',
      'gender': '${user.gender}',
      'authentifyBy': '${user.authentifyBy}'
    })
        .then((value) => print('user added'))
        .catchError((error) => print('Failed to add the user to Firestore'));
  }

  Future<User?> getUser(String email) async {
    // Fetch user data from the 'users' collection
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
        age: doc['age'] ?? '',
        gender: doc['gender'] ?? '',
        phoneNumber: doc['phoneNumber'] ?? '',
        authentifyBy: doc['authentifyBy'] ?? '',
      );
    }
    return null;
  }


  Future<void> updateUser(String id, User user) async {
    await users
        .doc(id)
        .update({
      'firstName': '${user.firstName}',
      'lastName': '${user.lastName}',
      'email': '${user.email}',
      'password': '${user.password}',
      'age': '${user.age}',
      'gender': '${user.gender}',
      'authentifyBy': '${user.authentifyBy}'
    })
        .then((value) => print('user updated'))
        .catchError((error) => print('Failed to update the user to Firestore'));
  }

  Future<void> deleteUser(String id) async {
    await users
        .doc(id)
        .delete()
        .then((value) => print('users deleted'))
        .catchError((error) =>
        print('Failed to delete the users in Firestore'));
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

    // Fetch appointments where date is today or in the future
    QuerySnapshot snapshot = await appointment
        .where('email', isEqualTo: currentUser?.email)
        .where('date', isGreaterThanOrEqualTo: today)
        .orderBy('date')
        .get();

    List<Appointment> appointments = [];

    if (snapshot.docs.isNotEmpty) {
      // Initialize DateFormat for parsing date and time
      DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      DateFormat dayFormat = DateFormat('MMMM d, yyyy');

      appointments = snapshot.docs.map((doc) {
        String dateString = doc['date'] ?? '';
        String timeString = doc['time'] ?? '';

        // If dateString contains both date and time, format it to only include the date
        String formattedDate;
        try {
          DateTime dateTime = dateFormat.parse(dateString);
          formattedDate =
              dateFormat.format(dateTime); // Extract only the date part
        } catch (e) {
          print('Error parsing date: $e');
          return null;
        }

        // Combine formatted date and time strings for parsing the full DateTime
        DateTime appointmentDateTime;
        try {
          appointmentDateTime =
              dateFormat.parse(formattedDate + ' ' + timeString);
        } catch (e) {
          print('Error parsing date and time: $e');
          return null;
        }

        // Only include future or current appointments
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

    // Fetch appointments where date is today or in the future
    QuerySnapshot snapshot = await appointment
        .where('email', isEqualTo: currentUser?.email)
        .get();

    List<Appointment> appointments = [];

    if (snapshot.docs.isNotEmpty) {
      // Initialize DateFormat for parsing date and time
      DateFormat dateFormat = DateFormat(
          'yyyy-MM-dd'); // Adjust based on the actual format stored in Firestore
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
    // Fetch the list of appointments from Firestore
    List<
        Appointment> appointments = await getHistory(); // Assuming getHistory fetches the appointments

    // Helper function to get the week number from a date
    int getWeekNumber(DateTime date) {
      var formatter = DateFormat('w');
      return int.parse(formatter.format(date));
    }

    // Group appointments by week
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

    // Convert the map of weekly groups into a list of lists
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
    this.notifyBy = "email", // Default value
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
