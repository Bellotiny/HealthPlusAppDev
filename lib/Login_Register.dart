import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'AppointmentDatabase.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //Access to the database which was coded outside
  final DatabaseAccess _db = DatabaseAccess();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);

    Future<void> verify(BuildContext context) async {
      if(await _db.login(_emailController.text,_passwordController.text)){
        print("Fire Authentication Login successful!");
        Navigator.pushNamed(
            context,
            '/validate',
            arguments: {"action": "main"}
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Health +',
          style: TextStyle(fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 50,
                ),
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
                      '${bundle.translation('login')}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: bundle.currentLanguage == 'EN' ? 52 : 46,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                ),
                Container(
                    padding: EdgeInsets.only(left: 40, right: 40),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "${bundle.translation('email')}",
                        // The label text on top
                        hintText: "${bundle.translation('emailTextField')}",
                        // Example text inside the box
                        border: OutlineInputBorder(),
                        // Full border around the TextField
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textDirection: TextDirection
                          .ltr, // Text direction from left to right
                    )),
                SizedBox(
                  height: 55,
                ),
                Container(
                  padding: EdgeInsets.only(left: 40, right: 40),
                  child: TextField(
                    obscureText: true,
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('password')}",
                      hintText: "${bundle.translation('passwordTextField')}",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    //Make sure it writes from left to right
                    textDirection: TextDirection.ltr,
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/register',
                            );
                          },
                          child: Text("${bundle.translation('register')}")),
                    ),
                    Container(
                      width: 140, // Specify the width of the button here
                      child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async{
                            await verify(context);
                          },
                          child: Text(
                            "${bundle.translation('login')}",
                            style: TextStyle(
                                fontSize:
                                    bundle.currentLanguage == 'EN' ? 12 : 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 44, vertical: 12),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (await _db.getUser(_emailController.text) != null) {
                        //Send 2FA
                        _db.sendPasswordResetEmail(_emailController.text);
                        Navigator.pushNamed(
                          context,
                          '/validate',
                          arguments: {'action': 'forgetPassword'},
                        );
                      }else{
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("${bundle.translation('noEmailInputted')}"),
                              content: Text('${bundle.translation('inputEmail')}'),
                            );
                          },
                        );
                      }
                    },
                    child: Text("${bundle.translation('forgotPassword')}")),
                SizedBox(
                  height: 45,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // Switch between English and French
                        if (bundle.currentLanguage == 'EN') {
                          await bundle.switchLanguage('FR'); // Switch to French
                        } else {
                          await bundle
                              .switchLanguage('EN'); // Switch to English
                        }
                      },
                      child: Text(
                        bundle.currentLanguage == 'EN'
                            ? "${bundle.translation('french')}" // If current language is English, show French
                            : "${bundle.translation('english')}", // Otherwise, show English
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final DatabaseAccess _db = DatabaseAccess();
  String? _authentifyBy = 'E-Mail';
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _ageController.clear();
      _genderController.clear();
      _phoneNumberController.clear();
      _passwordController.clear();
    });
  }

  Future<bool> isAccountNotUsed(BuildContext context, Localization bundle) async {

    if(_firstNameController.text.isEmpty||_lastNameController.text.isEmpty||_emailController.text.isEmpty||
        _passwordController.text.isEmpty||_ageController.text.isEmpty||_genderController.text.isEmpty||
        _phoneNumberController.text.isEmpty){
      _showErrorMessage(context, '${bundle.translation('missingField')}',bundle);
      return false;
    }
    if (int.tryParse(_ageController.text) == null) {
      _showErrorMessage(context, '${bundle.translation('invalidAge')}', bundle);
      return false;
    }

    if (await _db.getUser(_emailController.text) == null) {
      // Check if the password matches the confirmed password
      if (await verifyPassword()) {
        // Password matches constraints
        return true;
      } else {
        // Password is incorrect
        _showErrorMessage(context,
            "${bundle.translation('passwordRequirement')}", bundle);
        return false;
      }
    } else {
      // UserID already in use in the database
      _showErrorMessage(context, "${bundle.translation('accountUsed')}", bundle);
      return false;
    }
  }

  void _showErrorMessage(BuildContext context, String message, Localization bundle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${bundle.translation('registrationFailed')}"),
          content: Text(message),
        );
      },
    );
  }

  Future<bool> verifyPassword() async {
    return _passwordController.text
        .contains(RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{6,}$'));
  }

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Health +',
          style: TextStyle(fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 30,
                ),
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
                      '${bundle.translation('register')}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: bundle.currentLanguage == 'EN' ? 52 : 46,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 45,
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('firstName')}",
                      hintText: "${bundle.translation('firstNameTextField')}",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('lastName')}",
                      hintText: "${bundle.translation('lastNameTextField')}",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('email')}",
                      hintText: "${bundle.translation('emailTextField')}",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('age')}",
                      hintText: "${bundle.translation('ageTextField')}",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _genderController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('gender')}",
                      hintText: "${bundle.translation('genderTextField')}",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('phone')}",
                      hintText: "+1 222-333-4444",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "${bundle.translation('password')}",
                      hintText: "${bundle.translation('passwordTextField')}",
                      border: OutlineInputBorder(),
                      // Full border around the TextField
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      //Check if the userID doesn't already exist so no problem occurs in database insert
                      if (await isAccountNotUsed(context,bundle)) {
                        _db.addUser(User(
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            age: int.parse(_ageController.text),
                            gender: _genderController.text,
                            password: _passwordController.text,
                            phoneNumber: _phoneNumberController.text,
                            authentifyBy: _authentifyBy));
                        //Go back to Login
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text("${bundle.translation('register')}")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ValidateScreen extends StatefulWidget {

  const ValidateScreen({super.key});

  @override
  State<ValidateScreen> createState() => _ValidateScreenState();
}


class _ValidateScreenState extends State<ValidateScreen> {
  final DatabaseAccess _db = DatabaseAccess();
  late String? action;
  late TextEditingController _codeController = TextEditingController();
  bool isCheckingVerification = false;

  Future<void> _startEmailVerificationCheck(Localization bundle) async {
    setState(() {
      isCheckingVerification = true;
    });

    final verified = await waitForEmailVerification(maxRetries: 10);
    setState(() {
      isCheckingVerification = false;
    });

    if (verified) {
      print(action);
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // Show error if the verification wasn't completed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bundle.translation('emailNotVerified')}')),
      );
    }
  }

  Future<bool> waitForEmailVerification({int maxRetries = 10, Duration interval = const Duration(seconds: 3)}) async {
    for (int i = 0; i < maxRetries; i++) {
      final isVerified = await _db.isEmailVerified();
      if (isVerified) {
        return true;
      }

      // Wait for the next retry
      await Future.delayed(interval);
    }
    return false; // Verification not completed within the retries
  }

  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context);

    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    action = routeArgs?['action'];

    return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: const Text('Health +', style: TextStyle(fontSize: 24)),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isCheckingVerification || action=="forgetPassword"
            ? const CircularProgressIndicator() // Show loader during polling
            : _buildEmail(context, bundle),
      ),
    ),
    );
  }

  Column _buildEmail(BuildContext context, Localization bundle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
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
            child: Text(action!="forgetPassword" ?
              '${bundle.translation('verifyIdentity')}':
              '${bundle.translation('passwordChanged')}',
              style: TextStyle(
                color: Colors.white,
                fontSize: bundle.currentLanguage == 'EN' ? 36 : 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
         Text(action!="forgetPassword"?
         '${bundle.translation('emailSent')}':
         '${bundle.translation('emailPasswordReset')}'),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: (){_startEmailVerificationCheck(bundle);},
          child: Text(bundle.translation('verifyEmail')),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: _db.sendEmailVerification,
          child: Text(bundle.translation('resendEmail')),
        ),
      ],
    );
  }
}
