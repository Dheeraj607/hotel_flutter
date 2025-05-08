import 'package:flutter/material.dart';
import 'package:hotel_management/screens/all_rooms.dart';
import 'package:hotel_management/screens/settings.dart';
import 'room_detail_screen.dart';
import 'rooms.dart';

class DashboardScreen extends StatefulWidget {
  final int selectedIndex;

  const DashboardScreen({super.key, this.selectedIndex = 0});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  // List of screen widgets for each tab
  final List<Widget> _screens = [
    UnoccupiedRoomsScreen(), // Book a Room
    RoomDetailsScreen(), // Booked Rooms
    AllRoomsScreen(), // All Rooms
    SettingsPage(), // Settings
  ];

  // // App bar titles corresponding to each screen
  // final List<String> _titles = [
  //   "Book a Room",
  //   "Booked Rooms",
  //   "All Rooms",
  //   "Settings",
  // ];

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        widget
            .selectedIndex; // Set the initial selected index based on the passed value
  }

  // Handle bottom navigation tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.hotel),
            label: 'Book a Room',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Booked Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'All Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

Widget _buildDashboardCard(
  BuildContext context,
  String title,
  IconData icon,
  Widget targetScreen,
) {
  return GestureDetector(
    onTap: () {
      if (targetScreen is RoomDetailsScreen) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
          (Route<dynamic> route) => false, // Removes all previous screens
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      }
    },
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}
