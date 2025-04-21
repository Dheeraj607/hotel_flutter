import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/add_maintenance_request_screen.dart';
import 'package:hotel_management/screens/modify_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MaintenanceRequestScreen extends StatefulWidget {
  final String roomId;
  final String roomNumber;
  final String roomType;
  final String status;

  const MaintenanceRequestScreen({
    super.key,
    required this.roomId,
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
    try {
      final response = await http.get(
        Uri.parse(
          '$kBaseurl/api/maintenance-requests-with-staff/?roomId=${widget.roomId}',
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final assignment = item['maintenanceAssignment'];
          String maintenanceType = item['typeName'] ?? "N/A";
          String role = assignment?['maintenanceStaffRole'] ?? "N/A";

          if (maintenanceType.toLowerCase().contains('plumb')) {
            role = "Plumber";
          } else if (maintenanceType.toLowerCase().contains('electric')) {
            role = "Electrician";
          } else if (maintenanceType.toLowerCase().contains('clean')) {
            role = "Cleaner";
          }

          return {
            'requestId': item['requestId'],
            'typeId': item['typeId'],
            'maintenanceType': maintenanceType,
            'maintenanceStaffRole': role,
            'priorityLevel': item['priorityLevel'] ?? "N/A",
            'requestDate': item['requestDate'] ?? "",
            'assignedTo': assignment?['maintenanceStaffName'] ?? "Not Assigned",
            'status': item['status'] ?? "N/A",
            'issueDescription': item['issueDescription'] ?? "No Description",
          };
        }).toList();
      } else {
        throw Exception('Failed to load maintenance requests');
      }
    } catch (error) {
      throw Exception('Error fetching data: $error');
    }
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd MMM yyyy').format(parsedDate);
  }

  void _onAddMaintenanceRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddMaintenanceRequestScreen(
              roomNumber: widget.roomNumber,
              roomType: widget.roomType,
              status: widget.status,
              roomId: int.parse(widget.roomId),
              requestId: 0, // New requestId for adding a new request
            ),
      ),
    ).then((_) {
      setState(() {
        _maintenanceRequests = _fetchMaintenanceRequests();
      });
    });
  }

  void _showIssueDescriptionBottomSheet(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Issue Description',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                request['issueDescription'] ?? "No description provided",
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                            final int reqid = request['requestId'];
                            final int typeid = request['typeId'];

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
                                      'Type: ${request['maintenanceType'].toUpperCase().replaceAll('_', ' ')}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Priority Level: ${request['priorityLevel']}',
                                    ),
                                    Text(
                                      'Assigned to: ${request['assignedTo']}',
                                    ),
                                    Text('Request Date: $formattedDate'),
                                    Text(
                                      'Status: ${request['status']}',
                                      style: TextStyle(
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
                                            // Navigate to AddMaintenanceRequestScreen with existing request data
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => AddMaintenanceRequestScreen(
                                                      roomNumber:
                                                          widget.roomNumber,
                                                      roomType: widget.roomType,
                                                      status: widget.status,
                                                      roomId: int.parse(
                                                        widget.roomId,
                                                      ),
                                                      requestId:
                                                          reqid, // Pass requestId to pre-fill the form
                                                    ),
                                              ),
                                            ).then((_) {
                                              setState(() {
                                                _maintenanceRequests =
                                                    _fetchMaintenanceRequests();
                                              });
                                            });
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
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        ModifyReqScreen(
                                                          reqid: reqid,
                                                          typeid: typeid,
                                                          roomId: widget.roomId,
                                                          roomNumber:
                                                              widget.roomNumber,
                                                          roomType:
                                                              widget.roomType,
                                                          status: widget.status,
                                                        ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.assignment_ind_outlined,
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
                                            _showIssueDescriptionBottomSheet(
                                              request,
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
        onPressed: _onAddMaintenanceRequest,
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
