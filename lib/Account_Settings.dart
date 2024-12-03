import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'SettingsControl.dart';
import 'package:provider/provider.dart';
import 'Localization.dart';
import 'package:path/path.dart';
import 'AppointmentDatabase.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final DatabaseAccess _db = DatabaseAccess();

  String? _authentifyBy = '';
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    // Don't use context here because it's not fully available
    fillForm();
  }

  Future<void> fillForm() async {
    currentUser = await _db.currentUser;
    if (currentUser != null) {
      setState(() {
        _firstNameController.text = currentUser!.firstName;
        _lastNameController.text = currentUser!.lastName;
        _ageController.text = currentUser!.age.toString();
        _genderController.text = currentUser!.gender;
        _phoneNumberController.text = currentUser!.phoneNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    currentUser = Provider.of<DatabaseAccess>(context).currentUser;
    final bundle = Provider.of<Localization>(context);

    void _showErrorMessage(BuildContext context, String message) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Profile Change Failed"),
            content: Text(message),
          );
        },
      );
    }

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Health +',style: TextStyle(fontSize: 24),),
          actions: [
            IconButton(
              icon: Icon(Icons.logout,size: 30,), // Right icon
              onPressed: () {
                _db.logout();
                Navigator.pushNamed(
                  context,
                  '/login',
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50,),
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
                        '${bundle.translation('accountTitle')}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: bundle.currentLanguage == 'EN' ? 30:26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40,),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: "${bundle.translation('firstName')}",
                        //hintText: "${bundle.translation('firstNameTextField')}",
                        border: OutlineInputBorder(), // Full border around the TextField
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  SizedBox(height: 40,),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: "${bundle.translation('lastName')}",
                        //hintText: "${bundle.translation('lastNameTextField')}",
                        border: OutlineInputBorder(), // Full border around the TextField
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  SizedBox(height: 40,),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: "${bundle.translation('age')}",
                        //hintText: "${bundle.translation('ageTextField')}",
                        border: OutlineInputBorder(), // Full border around the TextField
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(height: 40,),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      controller: _genderController,
                      decoration: InputDecoration(
                        labelText: "${bundle.translation('gender')}",
                        //hintText: "${bundle.translation('genderTextField')}",
                        border: OutlineInputBorder(), // Full border around the TextField
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  SizedBox(height: 40,),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        labelText: "${bundle.translation('phone')}",
                        //hintText: "${bundle.translation('phoneTextField')}",
                        border: OutlineInputBorder(), // Full border around the TextField
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  SizedBox(height: 60,),
                  Row(crossAxisAlignment: CrossAxisAlignment.center,
                    children: [ SizedBox(width: bundle.currentLanguage == 'EN' ? 60:30,),Text("${bundle.translation('authenticate')}"),],),
                  SizedBox(height: 20,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 90),
                      Radio<String>(
                        value: "email",
                        groupValue: currentUser?.authentifyBy,
                        onChanged: (String? value) {
                          setState(() {
                            _authentifyBy = value;
                          });
                        },
                      ),
                      Text(bundle.translation('email')),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 90),
                      Radio<String>(
                        value: "${bundle.translation('phone')}",
                        groupValue: currentUser?.authentifyBy,
                        onChanged: (String? value) {
                          setState(() {
                            _authentifyBy = value;
                          });
                        },
                      ),
                      Text(bundle.translation('phone')),
                    ],
                  ),
                  SizedBox(height: 40,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        onPressed: () async {
                          // Input validation
                          if (_firstNameController.text.isEmpty ||
                              _lastNameController.text.isEmpty ||
                              _ageController.text.isEmpty ||
                              _genderController.text.isEmpty ||
                              _phoneNumberController.text.isEmpty) {
                            // Show a message or alert about missing fields
                            _showErrorMessage(context, '${bundle.translation('missingField')}');
                            return;
                          }

                          // Validate the age is a valid number
                          if (int.tryParse(_ageController.text) == null) {
                            print("Please enter a valid age");
                            return;
                          }

                          // Proceed with updating the user
                          try {
                            await _db.updateUser(currentUser!.email,
                                User(
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  email: currentUser!.email,
                                  age: int.parse(_ageController.text),
                                  gender: _genderController.text,
                                  password: currentUser!.password,
                                  phoneNumber: _phoneNumberController.text,
                                  authentifyBy: _authentifyBy,
                                ));
                            // Optionally show a success message
                            print("User updated successfully.");
                          } catch (e) {
                            // Handle any errors during update
                            print("Failed to update user: $e");
                          }
                        },
                        child: Text("${bundle.translation('save')}"),
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? currentUser;
  String? _language;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bundle = Provider.of<Localization>(context as BuildContext, listen: false);

      await bundle.loadLanguagePreference();

      setState(() {
        _language = bundle.currentLanguage;
      });

      // Optionally load the language translations
      await bundle.readJSON();
    });
  }

  // Modes: 0:light, 1:dark, 2:inverse
  int? _themeMode;

  @override
  Widget build(BuildContext context) {
    currentUser = Provider.of<DatabaseAccess>(context).currentUser;
    final bundle = Provider.of<Localization>(context);
    final themeControl = Provider.of<ThemeControl>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Health +', style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            icon: Icon(Icons.person, size: 30), // Right icon
            onPressed: () {
              Navigator.pushNamed(context, '/account');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50,),
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
                      '${bundle.translation('settings')}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: bundle.currentLanguage == 'EN' ? 52:46,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [SizedBox(width: 100), Text('${bundle.translation('appearance')}')],
                ),
                SizedBox(height: 20),
                // Theme Mode Selection
                buildThemeModeRadio(bundle, themeControl),
                SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [SizedBox(width: 100), Text('${bundle.translation('language')}')],
                ),
                SizedBox(height: 20),
                // Language Selection
                buildLanguageSelection(bundle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build theme mode radio options
  Column buildThemeModeRadio(Localization bundle, ThemeControl themeControl) {
    return Column(
      children: [
        buildRadioOption(0, bundle.translation('lightMode'), themeControl),
        buildRadioOption(1, bundle.translation('darkMode'), themeControl),
        buildRadioOption(2, bundle.translation('invertedMode'), themeControl),
      ],
    );
  }

  // Helper method to build each radio option for theme mode
  Row buildRadioOption(int value, String label, ThemeControl themeControl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 100),
        Radio<int>(
          value: value,
          groupValue: themeControl.themeMode,
          onChanged: (int? value) {
            if (value != null) {
              themeControl.setThemeMode(value);
            }
          },
        ),
        Text(label),
      ],
    );
  }

  // Build language selection radio options
  Column buildLanguageSelection(Localization bundle) {
    return Column(
      children: [
        buildLanguageRadio('EN', bundle.translation('english'), bundle),
        buildLanguageRadio('FR', bundle.translation('french'), bundle),
      ],
    );
  }

  // Helper method to build each radio option for language
  Row buildLanguageRadio(String value, String label, Localization bundle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 100),
        Radio<String>(
          value: value,
          groupValue: bundle.currentLanguage,
          onChanged: (String? value) async {
            if (value != null) {
              await bundle.switchLanguage(value); // Save and switch language
            }
          },
        ),
        Text(label),
      ],
    );
  }
}

