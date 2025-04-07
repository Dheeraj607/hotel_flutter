import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'maintenance_request_screen.dart'; // Import the new screen

class AllRoomsScreen extends StatefulWidget {
  const AllRoomsScreen({super.key});

  @override
  State<AllRoomsScreen> createState() => _AllRoomsScreenState();
}

class _AllRoomsScreenState extends State<AllRoomsScreen> {
  List<dynamic> rooms = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    final url = Uri.parse("$kBaseurl/api/rooms/");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          rooms = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to load rooms. Status code: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error fetching rooms: $e";
        isLoading = false;
      });
    }
  }

  void handleMaintenance(String roomNumber, String roomType, String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MaintenanceRequestScreen(
              roomNumber: roomNumber,
              roomType: roomType,
              status: status,
            ),
      ),
    );
  }

  Widget buildRoomCard(Map<String, dynamic> room) {
    final roomNumber = room['roomNumber'] ?? 'N/A';
    final roomType = room['roomType'] ?? 'N/A';
    final status = room['status'] ?? 'N/A';

    final isOccupied = status.toLowerCase() == 'occupied';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOccupied ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOccupied ? Colors.red : Colors.green,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Room Number: $roomNumber",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text("Room Type: $roomType"),
          const SizedBox(height: 4),
          Text(
            "Status: $status",
            style: TextStyle(
              color: isOccupied ? Colors.red : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => handleMaintenance(roomNumber, roomType, status),
              icon: const Icon(Icons.build, size: 18),
              label: const Text("Maintenance"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Rooms"),
        backgroundColor: Colors.teal,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
              : rooms.isEmpty
              ? const Center(child: Text("No rooms available."))
              : ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  return buildRoomCard(rooms[index]);
                },
              ),
    );
  }
}
