import 'dart:async';
import 'package:flutter/material.dart';
import 'Modify.dart';
import 'package:provider/provider.dart';
import 'AppointmentDatabase.dart';
import 'Localization.dart';
import 'Login_Register.dart';
import 'MainScreen.dart';
import 'Booking.dart';
import 'ModifyView.dart';
import 'View.dart';
import 'History.dart';
import 'Account_Settings.dart';
import 'SettingsControl.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyAdWzb4aEOxT3TV3N0QvyUcDM1YqcBCQ2o",
          appId: "1:1034097704666:android:8d4fb70b9ee93c6731afe3",
          messagingSenderId: "1034097704666",
          projectId: "healthplus-7f47c"
      )
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => Localization()..readJSON(),
        ),
        ChangeNotifierProvider<DatabaseAccess>(
          create: (context) => DatabaseAccess(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeControl(),
        ),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeControl = Provider.of<ThemeControl>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeControl.currentTheme,
      title: 'Health Plus',
      initialRoute: '/',
      routes: {
        '/': (context) => InitialScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/validate': (context) => ValidateScreen(),
        '/forgetPassword': (context) => ForgetPasswordScreen(),
        '/main': (context) => MainScreen(),
        '/booking': (context) => BookingScreen(),
        '/modify': (context) => ModifyView(),
        '/view': (context) => ViewScreen(),
        '/history': (context) => HistoryScreen(),
        '/settings': (context) => SettingsScreen(),
        '/account': (context) => AccountScreen(),
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () async{
      DatabaseAccess _db = DatabaseAccess();
      if(await _db.loadUser()){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else{
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox.expand(
          child: Center(
            child: Image.asset('assets/health-plus-logo.png'),
          ),
        ),
      ),
    );
  }
}
