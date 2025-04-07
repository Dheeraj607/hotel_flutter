import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/booking_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UnoccupiedRoomsScreen extends StatefulWidget {
  const UnoccupiedRoomsScreen({super.key});

  @override
  _UnoccupiedRoomsScreenState createState() => _UnoccupiedRoomsScreenState();
}

class _UnoccupiedRoomsScreenState extends State<UnoccupiedRoomsScreen> {
  List<dynamic> unoccupiedRooms = [];
  bool isLoading = true;
  String errorMessage = '';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchUnoccupiedRooms();
  }

  Future<void> fetchUnoccupiedRooms() async {
    if (selectedDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      setState(() {
        unoccupiedRooms = [];
        isLoading = false;
        errorMessage = 'Cannot show availability for past dates.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$kBaseurl/api/rooms/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> filtered =
            data.where((room) => room['status'] == 'Unoccupied').toList();

        setState(() {
          unoccupiedRooms = filtered;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(), // Prevent past dates from being picked
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchUnoccupiedRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Unoccupied Rooms'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Selected Date: $formattedDate",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: Icon(Icons.calendar_today),
                  label: Text("Pick Date"),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : unoccupiedRooms.isEmpty
                    ? Center(child: Text("No unoccupied rooms found"))
                    : ListView.builder(
                      itemCount: unoccupiedRooms.length,
                      itemBuilder: (context, index) {
                        final room = unoccupiedRooms[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BookRoomScreen(
                                      roomData: room,
                                      checkInDate: selectedDate,
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Room No: ${room['roomNumber']}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text("Room Type: ${room['roomType']}"),
                                  Text("Rent: ₹${room['Rent']}"),
                                  Text("Advance: ₹${room['Advance']}"),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
