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
      firstDate: DateTime.now(),
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
        title: const Text('Unoccupied Rooms'),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                title: Text(
                  "Selected Date: $formattedDate",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  onPressed: _pickDate,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : unoccupiedRooms.isEmpty
                    ? const Center(child: Text("No unoccupied rooms found"))
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: unoccupiedRooms.length,
                      itemBuilder: (context, index) {
                        final room = unoccupiedRooms[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          child: InkWell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    'https://images.unsplash.com/flagged/photo-1556438758-8d49568ce18e?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&ixid=eyJhcHBfaWQiOjEyMDd9',
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Room No: ${room['roomNumber']}",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              "${room['roomType']}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.attach_money,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Rent: ₹${room['Rent']}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.savings, size: 20),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Advance: ₹${room['Advance']}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () {
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
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text("Book Now"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
