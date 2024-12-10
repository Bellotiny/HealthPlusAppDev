import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class Localization with ChangeNotifier {
  Map<String, dynamic> _bundleEN = {};
  Map<String, dynamic> _bundleFR = {};
  String _currentLanguage = 'EN';

  Map<String, dynamic> get bundleEN => _bundleEN;
  Map<String, dynamic> get bundleFR => _bundleFR;
  String get currentLanguage => _currentLanguage;

  Future<void> readJSON() async {
    try {
      final String response = await rootBundle.loadString('assets/lang.json');
      final Map<String, dynamic> data = json.decode(response);

      _bundleEN = Map<String, dynamic>.from(data["langEN"][0]);
      _bundleFR = Map<String, dynamic>.from(data["langFR"][0]);

      //print('EN Bundle Loaded: $_bundleEN');
      //print('FR Bundle Loaded: $_bundleFR');
    } catch (e) {
      print('Error loading JSON: $e');
    }
    notifyListeners();
  }

  // Load the saved language preference
  Future<void> loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selectedLanguage') ?? 'EN';
    notifyListeners();
  }

  // Switch between languages
  Future<void> switchLanguage(String language) async {
    _currentLanguage = language;

    // Save the selected language to shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);

    notifyListeners();
  }

  // Translate a key with optional variables
  String translation(String key, [Map<String, String>? variables]) {
    Map<String, dynamic> bundle =
    _currentLanguage == 'EN' ? _bundleEN : _bundleFR;

    String template = bundle[key] ?? key;

    if (variables != null) {
      variables.forEach((placeholder, value) {
        template = template.replaceAll('{$placeholder}', value);
      });
    }

    return template;
  }
}