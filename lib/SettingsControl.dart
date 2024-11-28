import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Localization.dart'; // Import the Localization class

class CustomBottomNavBar extends StatelessWidget {
  final int selectedNavItem;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedNavItem,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bundle = Provider.of<Localization>(context); // Get the current Localization

    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: bundle.translation('booking'), // Localized label
          backgroundColor: Colors.blueAccent,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: bundle.translation('modify'),
          backgroundColor: Colors.blueAccent,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: bundle.translation('home'),
          backgroundColor: Colors.blueAccent,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          label: bundle.translation('view'),
          backgroundColor: Colors.blueAccent,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: bundle.translation('history'),
          backgroundColor: Colors.blueAccent,
        ),
      ],
      type: BottomNavigationBarType.shifting,
      currentIndex: selectedNavItem,
      selectedItemColor: Colors.white,  // Color of icon and label when selected
      unselectedItemColor: Colors.grey,  // Color of icon and label when unselected
      selectedLabelStyle: TextStyle(color: Colors.white),  // Style for selected label
      selectedIconTheme: IconThemeData(color: Colors.white),  // Icon color for selected item
      unselectedLabelStyle: TextStyle(color: Colors.black),  // Style for unselected label
      unselectedIconTheme: IconThemeData(color: Colors.black),
      iconSize: 30,
      onTap: (index) {
        onItemTapped(index);
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/booking');
            break;
          case 1:
            Navigator.pushNamed(context, '/modify');
            break;
          case 2:
            Navigator.pushNamed(context, '/main');
            break;
          case 3:
            Navigator.pushNamed(context, '/view');
            break;
          case 4:
            Navigator.pushNamed(context, '/history');
            break;
          default:
            break;
        }
      },
      elevation: 4,
    );
  }
}

class ThemeControl with ChangeNotifier {
  // Default to light theme
  int _themeMode = 0;

  int get themeMode => _themeMode;

  // Update the theme mode and notify listeners
  void setThemeMode(int mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Return the current theme based on the theme mode
  ThemeData get currentTheme {
    switch (_themeMode) {
      case 0:
        return ThemeData.light().copyWith(
          appBarTheme: AppBarTheme(
            color: Colors.blueAccent,
            foregroundColor: Colors.black,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          scaffoldBackgroundColor: Colors.white,
          textTheme: ThemeData.light().textTheme.copyWith(
            bodySmall: TextStyle(color: Colors.black),
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
          ),
          iconTheme: IconThemeData(color: Colors.black),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              iconColor: WidgetStateProperty.all(Colors.black),
            ),
          ),
        );
      case 1:
        return ThemeData(
          brightness: Brightness.dark,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          scaffoldBackgroundColor: Colors.blue[800],
          textTheme: TextTheme(
            bodySmall: TextStyle(color: Colors.white),
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              iconColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
        );
      case 2:
        return ThemeData(
          brightness: Brightness.light,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.grey,
            titleTextStyle: TextStyle(
              color: Colors.grey,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          scaffoldBackgroundColor: Colors.blueAccent,
          textTheme: TextTheme(
            bodySmall: TextStyle(color: Colors.grey),
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black),
          ),
          iconTheme: IconThemeData(color: Colors.grey),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              iconColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
        );
      default:
        return ThemeData.light(); // Default theme
    }
  }
}