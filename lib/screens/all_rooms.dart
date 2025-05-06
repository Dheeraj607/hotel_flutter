import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'maintenance_request_screen.dart';

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

  Future<void> handleMaintenance(
    String roomId,
    String roomNumber,
    String roomType,
    String status,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MaintenanceRequestScreen(
              roomId: roomId,
              roomNumber: roomNumber,
              roomType: roomType,
              status: status,
            ),
      ),
    );

    if (result == true) {
      fetchRooms();
    }
  }

  Widget buildRoomCard(Map<String, dynamic> room) {
    final roomId = room['roomId']?.toString() ?? 'N/A';
    final roomNumber = room['roomNumber'] ?? 'N/A';
    final roomType = room['roomType'] ?? 'N/A';
    final status = room['status'] ?? 'N/A';
    final latestMaintenance = room['latestMaintenance'];
    final isOccupied = status.toString().toLowerCase() == 'occupied';

    // Placeholder image URL (you can replace it with actual image asset or URL)
    const String imageUrl =
        "https://images.unsplash.com/flagged/photo-1556438758-8d49568ce18e?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&ixid=eyJhcHBfaWQiOjEyMDd9";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
            ),
          ),

          // Room Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room No: $roomNumber",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Room Type: $roomType",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  "Status: $status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOccupied ? Colors.red : Colors.green,
                  ),
                ),
                if (latestMaintenance != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Last Maintenance: $latestMaintenance",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.deepOrange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Maintenance Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed:
                        () => handleMaintenance(
                          roomId,
                          roomNumber.toString(),
                          roomType.toString(),
                          status.toString(),
                        ),
                    icon: const Icon(Icons.build, size: 20),
                    label: const Text("Maintenance"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 245, 129, 86),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
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
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
        elevation: 0,
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
