import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

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

  Future<bool> login(User? user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (user == null) {
      _currentUser = null;
      await prefs.remove('userEmail');
    } else {
      try{
        auth.UserCredential userCredential = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user.email,
          password: user.password,
        );

        if(userCredential != null){
          print('Logged in as: ${user.firstName} ${user.lastName}');
          _currentUser = user;
          await prefs.setString('userEmail', user.email);
          notifyListeners();
          print(currentUser.toString());
          if (currentUser?.authentifyBy == "E-Mail") {
            sendEmailVerification();
            return true;
          } else {
            sendPhoneVerification();
          }
        }else {
          print("No user logged in Firebase.");
          return false;
        }
      }catch (e) {
        print('Login failed: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> sendPhoneVerification() async {
    try {
      final phoneNumber = auth.FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        print("No phone number associated with the user.");
        return;
      }

      await auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (auth.PhoneAuthCredential credential) async {
          // Automatically signs in the user once the phone number is verified
          await auth.FirebaseAuth.instance.signInWithCredential(credential);
          print("Phone verification completed successfully.");
        },
        verificationFailed: (auth.FirebaseAuthException e) {
          // Handle errors like network issues or invalid phone numbers
          print("Phone verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          // Save the verification ID, which will be used later to verify the code
          this.verificationId = verificationId;
          print("Code sent to $phoneNumber");

          // Optionally, prompt the user to enter the verification code
          // You can create a UI for entering the code, or call a method here.
          // For example:
          // promptForCode();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // In case the automatic code retrieval times out
          this.verificationId = verificationId;
          print("Auto-retrieval timeout for $phoneNumber");
        },
      );
    } catch (e) {
      print("Error sending phone verification: $e");
    }
  }

  Future<bool> verifyPhoneCode(String smsCode) async {
    try {
      if (verificationId != null) {
        final auth.PhoneAuthCredential credential = auth.PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: smsCode,
        );

        // Sign in the user with the phone credential
        await auth.FirebaseAuth.instance.signInWithCredential(credential);
        print("Phone number verified successfully.");
        return true; // Return true if verification is successful
      } else {
        print("Verification ID is null, unable to verify the code.");
        return false; // Return false if verification ID is not available
      }
    } catch (e) {
      print("Error verifying phone number: $e");
      return false; // Return false if an error occurs during verification
    }
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

      // Reload user state from Firebase
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
        age: doc['age'] ?? 0,
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
  Future<bool> isSlotTaken(String doctorName, String date, String time) async {
    try {
      // Query Firestore for an appointment with the same doctor, date, and time
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Appointments') // Replace with your actual collection name
          .where('doctor', isEqualTo: doctorName)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .get();

      // If any documents are found, the slot is taken
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking slot availability: $e");
      return true; // Default to slot being taken if an error occurs
    }
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
