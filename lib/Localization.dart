import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class Localization with ChangeNotifier {
  List<Map<String, dynamic>> _bundleEN = [];
  List<Map<String, dynamic>> _bundleFR = [];
  String _currentLanguage = 'EN'; // Default language

  List<Map<String, dynamic>> get bundleEN => _bundleEN;
  List<Map<String, dynamic>> get bundleFR => _bundleFR;
  String get currentLanguage => _currentLanguage;

  // Fetch content from the local JSON file
  Future<void> readJSON() async {
    final String response = await rootBundle.loadString('assets/lang.json');
    final Map<String, dynamic> data = json.decode(response);

    _bundleEN = List<Map<String, dynamic>>.from(data["langEN"]);
    _bundleFR = List<Map<String, dynamic>>.from(data["langFR"]);

    notifyListeners();
  }

  // Load the saved language preference
  Future<void> loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selectedLanguage') ?? 'EN'; // Default to 'EN'
    notifyListeners(); // Notify listeners to update UI with the correct language
  }

  // Method to switch between languages
  Future<void> switchLanguage(String language) async {
    _currentLanguage = language;

    // Save the selected language to shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);

    notifyListeners(); // Notify widgets to rebuild with new language data
  }

  // Method to retrieve the translation based on the current language and key
  String translation(String key, [Map<String, String>? variables]) {
    List<Map<String, dynamic>> bundle =
    _currentLanguage == 'EN' ? _bundleEN : _bundleFR;

    // Retrieve the template for the given key
    String template = bundle.isNotEmpty ? bundle[0][key] ?? '' : '';

    // Replace placeholders in the template if variables are provided
    if (variables != null) {
      variables.forEach((placeholder, value) {
        template = template.replaceAll('{$placeholder}', value);
      });
    }

    return template;
  }

}
