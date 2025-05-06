import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart'; // Ensure this file exists!

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          const DashboardScreen(), // Make sure DashboardScreen is marked const
    );
  }
}
