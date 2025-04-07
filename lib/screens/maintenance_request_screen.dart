import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import the intl package

class MaintenanceRequestScreen extends StatefulWidget {
  final String roomNumber;
  final String roomType;
  final String status;

  const MaintenanceRequestScreen({
    super.key,
    required this.roomNumber,
    required this.roomType,
    required this.status,
  });

  @override
  _MaintenanceRequestScreenState createState() =>
      _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen> {
  late Future<List<Map<String, dynamic>>> _maintenanceRequests;

  @override
  void initState() {
    super.initState();
    _maintenanceRequests = _fetchMaintenanceRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchMaintenanceRequests() async {
    final response = await http.get(
      Uri.parse('$kBaseurl/api/maintenance-requests-with-staff/'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        return {
          'maintenanceType': item['maintenanceAssignment']['maintenanceType'],
          'priorityLevel': item['priorityLevel'],
          'requestDate': item['requestDate'],
          'assignedTo': item['maintenanceAssignment']['name'],
          'status': item['status'],
          'requestId': item['requestId'],
        };
      }).toList();
    } else {
      throw Exception('Failed to load maintenance requests');
    }
  }

  // Function to format the date to a readable format
  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat(
      'dd MMM yyyy',
    ).format(parsedDate); // Format date as "day month year"
  }

  // Function to handle the "+" button click
  void _onAddMaintenanceRequest() {
    // This function will be triggered when the "+" button is pressed
    print("Add maintenance request button clicked!");
    // Here you can navigate to another screen or show a dialog for adding a new request
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = widget.status.toLowerCase() == 'occupied';
    final statusColor = isOccupied ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Maintenance Request"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Room: ${widget.roomNumber}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Type: ${widget.roomType}",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "Status: ${widget.status}",
                style: TextStyle(fontSize: 18, color: statusColor),
              ),
              const SizedBox(height: 20),
              const Text(
                "Maintenance Requests:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _maintenanceRequests,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No maintenance requests found"),
                    );
                  } else {
                    final requests = snapshot.data!;
                    return Column(
                      children:
                          requests.map((request) {
                            String formattedDate = formatDate(
                              request['requestDate'],
                            );
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Maintenance Type: ${request['maintenanceType']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Priority Level: ${request['priorityLevel']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Assigned to: ${request['assignedTo']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Request Date: $formattedDate',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Status: ${request['status']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            request['status'].toLowerCase() ==
                                                    'completed'
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            print(
                                              'Edit button clicked for Request ID: ${request['requestId']}',
                                            );
                                          },
                                          icon: const Icon(Icons.edit),
                                          label: const Text("Edit"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            print(
                                              'Modify Assignment button clicked for Request ID: ${request['requestId']}',
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.assignment_ind,
                                          ),
                                          label: const Text("Modify"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            print(
                                              'View button clicked for Request ID: ${request['requestId']}',
                                            );
                                          },
                                          icon: const Icon(Icons.visibility),
                                          label: const Text("View"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _onAddMaintenanceRequest, // Trigger the add maintenance request function
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
