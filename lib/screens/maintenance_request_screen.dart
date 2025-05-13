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
  int maintenanceStaffId = 0;

  @override
  void initState() {
    super.initState();
    _maintenanceRequests = _fetchMaintenanceRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchMaintenanceRequests() async {
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

        if (maintenanceType.toLowerCase().contains('plumb'))
          role = "Plumber";
        else if (maintenanceType.toLowerCase().contains('electric'))
          role = "Electrician";
        else if (maintenanceType.toLowerCase().contains('clean'))
          role = "Cleaner";

        if (assignment != null) {
          setState(() {
            maintenanceStaffId = assignment["maintenanceStaffId"];
          });
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
              requestId: 0,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Issue Description',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(request['issueDescription']),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = widget.status.toLowerCase() == 'occupied';
    final statusColor = isOccupied ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Maintenance Request"),
        backgroundColor: Colors.orangeAccent,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Room ${widget.roomNumber}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("Type: ${widget.roomType}   "),
                  Text(
                    "Status: ${widget.status}",
                    style: TextStyle(color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                "Maintenance Requests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _maintenanceRequests,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("No maintenance requests found.");
                  }

                  return Column(
                    children:
                        snapshot.data!.map((request) {
                          final formattedDate = formatDate(
                            request['requestDate'],
                          );
                          final reqid = request['requestId'];
                          final typeid = request['typeId'];
                          final status = request['status'].toLowerCase();

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.build,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        request['maintenanceType']
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildChip(
                                    request['priorityLevel'],
                                    Colors.deepOrange,
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Assigned to: ${request['assignedTo']}"),
                                  Text("Date: $formattedDate"),
                                  _buildChip(
                                    request['status'],
                                    status == 'completed'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                    _,
                                                  ) => AddMaintenanceRequestScreen(
                                                    roomNumber:
                                                        widget.roomNumber,
                                                    roomType: widget.roomType,
                                                    status: widget.status,
                                                    roomId: int.parse(
                                                      widget.roomId,
                                                    ),
                                                    requestId: reqid,
                                                    maintenanceStaffId:
                                                        maintenanceStaffId,
                                                    maintenanceType:
                                                        request['maintenanceType'],
                                                  ),
                                            ),
                                          ).then(
                                            (_) => setState(() {
                                              _maintenanceRequests =
                                                  _fetchMaintenanceRequests();
                                            }),
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text("Edit"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => ModifyReqScreen(
                                                    reqid: reqid,
                                                    typeid: typeid,
                                                    roomId: widget.roomId,
                                                    roomNumber:
                                                        widget.roomNumber,
                                                    roomType: widget.roomType,
                                                    status: widget.status,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.settings),
                                        label: const Text("Modify"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            () =>
                                                _showIssueDescriptionBottomSheet(
                                                  request,
                                                ),
                                        icon: const Icon(Icons.visibility),
                                        color: Colors.teal,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddMaintenanceRequest,
        icon: const Icon(Icons.add),
        label: const Text("Add Request"),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:hotel_management/constant.dart';
// import 'package:hotel_management/screens/add_maintenance_request_screen.dart';
// import 'package:hotel_management/screens/modify_screen.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';

// class MaintenanceRequestScreen extends StatefulWidget {
//   final String roomId;
//   final String roomNumber;
//   final String roomType;
//   final String status;

//   const MaintenanceRequestScreen({
//     super.key,
//     required this.roomId,
//     required this.roomNumber,
//     required this.roomType,
//     required this.status,
//   });

//   @override
//   _MaintenanceRequestScreenState createState() =>
//       _MaintenanceRequestScreenState();
// }

// class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen> {
//   late Future<List<Map<String, dynamic>>> _maintenanceRequests;
//   int maintenanceStaffId = 0;
//   String maintenanceType = "";

//   @override
//   void initState() {
//     super.initState();
//     _maintenanceRequests = _fetchMaintenanceRequests();
//   }

//   Future<List<Map<String, dynamic>>> _fetchMaintenanceRequests() async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//           '$kBaseurl/api/maintenance-requests-with-staff/?roomId=${widget.roomId}',
//         ),
//       );

//       if (response.statusCode == 200) {
//         List<dynamic> data = json.decode(response.body);
//         return data.map((item) {
//           final assignment = item['maintenanceAssignment'];
//           String maintenanceType = item['typeName'] ?? "N/A";
//           String role = assignment?['maintenanceStaffRole'] ?? "N/A";

//           if (maintenanceType.toLowerCase().contains('plumb')) {
//             role = "Plumber";
//           } else if (maintenanceType.toLowerCase().contains('electric')) {
//             role = "Electrician";
//           } else if (maintenanceType.toLowerCase().contains('clean')) {
//             role = "Cleaner";
//           }
//           if (assignment != null) {
//             print(assignment["maintenanceStaffId"]);
//             setState(() {
//               maintenanceStaffId = assignment["maintenanceStaffId"];
//               maintenanceType = assignment["maintenanceType"];
//             });
//           }

//           return {
//             'requestId': item['requestId'],
//             'typeId': item['typeId'],
//             'maintenanceType': maintenanceType,
//             'maintenanceStaffRole': role,
//             'priorityLevel': item['priorityLevel'] ?? "N/A",
//             'requestDate': item['requestDate'] ?? "",
//             'assignedTo': assignment?['maintenanceStaffName'] ?? "Not Assigned",
//             'status': item['status'] ?? "N/A",
//             'issueDescription': item['issueDescription'] ?? "No Description",
//           };
//         }).toList();
//       } else {
//         throw Exception('Failed to load maintenance requests');
//       }
//     } catch (error) {
//       print("Error fetching data: $error");
//       throw Exception('Error fetching data: $error');
//     }
//   }

//   String formatDate(String date) {
//     DateTime parsedDate = DateTime.parse(date);
//     return DateFormat('dd MMM yyyy').format(parsedDate);
//   }

//   void _onAddMaintenanceRequest() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => AddMaintenanceRequestScreen(
//               roomNumber: widget.roomNumber,
//               roomType: widget.roomType,
//               status: widget.status,
//               roomId: int.parse(widget.roomId),
//               requestId: 0, // New requestId for adding a new request
//             ),
//       ),
//     ).then((_) {
//       setState(() {
//         _maintenanceRequests = _fetchMaintenanceRequests();
//       });
//     });
//   }

//   void _showIssueDescriptionBottomSheet(Map<String, dynamic> request) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         return Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Container(
//                   height: 5,
//                   width: 50,
//                   margin: const EdgeInsets.only(bottom: 20),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//               const Text(
//                 'Issue Description',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.teal,
//                 ),
//               ),
//               const SizedBox(height: 15),
//               Text(
//                 request['issueDescription'] ?? "No description provided",
//                 style: const TextStyle(
//                   fontSize: 16,
//                   height: 1.5,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Close'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.teal,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isOccupied = widget.status.toLowerCase() == 'occupied';
//     final statusColor = isOccupied ? Colors.red : Colors.green;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Maintenance Request"),
//         backgroundColor: const Color.fromARGB(255, 245, 129, 86),
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Room: ${widget.roomNumber}",
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Type: ${widget.roomType}",
//                 style: const TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Status: ${widget.status}",
//                 style: TextStyle(fontSize: 18, color: statusColor),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Maintenance Requests:",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//               ),
//               const SizedBox(height: 10),
//               FutureBuilder<List<Map<String, dynamic>>>(
//                 future: _maintenanceRequests,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     return Center(child: Text("Error: ${snapshot.error}"));
//                   } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return const Center(
//                       child: Text("No maintenance requests found"),
//                     );
//                   } else {
//                     final requests = snapshot.data!;

//                     return Column(
//                       children:
//                           requests.map((request) {
//                             String formattedDate = formatDate(
//                               request['requestDate'],
//                             );
//                             final int reqid = request['requestId'];
//                             final int typeid = request['typeId'];

//                             return Card(
//                               margin: const EdgeInsets.symmetric(vertical: 10),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               elevation: 5,
//                               child: Padding(
//                                 padding: const EdgeInsets.all(20),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Type: ${request['maintenanceType'].toUpperCase()}',
//                                       style: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 10),
//                                     Text(
//                                       'Priority: ${request['priorityLevel']}',
//                                       style: const TextStyle(fontSize: 14),
//                                     ),
//                                     Text(
//                                       'Assigned to: ${request['assignedTo']}',
//                                       style: const TextStyle(fontSize: 14),
//                                     ),
//                                     Text(
//                                       'Request Date: $formattedDate',
//                                       style: const TextStyle(fontSize: 14),
//                                     ),
//                                     Text(
//                                       'Status: ${request['status']}',
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         color:
//                                             request['status'].toLowerCase() ==
//                                                     'completed'
//                                                 ? Colors.green
//                                                 : Colors.red,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 15),
//                                     Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         ElevatedButton.icon(
//                                           onPressed: () {
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (
//                                                       context,
//                                                     ) => AddMaintenanceRequestScreen(
//                                                       roomNumber:
//                                                           widget.roomNumber,
//                                                       roomType: widget.roomType,
//                                                       status: widget.status,
//                                                       roomId: int.parse(
//                                                         widget.roomId,
//                                                       ),
//                                                       requestId: reqid,
//                                                       maintenanceStaffId:
//                                                           maintenanceStaffId,
//                                                       maintenanceType:
//                                                           "${request['maintenanceType'].toUpperCase()}",
//                                                     ),
//                                               ),
//                                             ).then((_) {
//                                               setState(() {
//                                                 _maintenanceRequests =
//                                                     _fetchMaintenanceRequests();
//                                               });
//                                             });
//                                           },
//                                           icon: const Icon(Icons.edit),
//                                           label: const Text("Edit"),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.orange,
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 15,
//                                               vertical: 12,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                         ),
//                                         ElevatedButton.icon(
//                                           onPressed: () {
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (context) =>
//                                                         ModifyReqScreen(
//                                                           reqid: reqid,
//                                                           typeid: typeid,
//                                                           roomId: widget.roomId,
//                                                           roomNumber:
//                                                               widget.roomNumber,
//                                                           roomType:
//                                                               widget.roomType,
//                                                           status: widget.status,
//                                                         ),
//                                               ),
//                                             );
//                                           },
//                                           icon: const Icon(
//                                             Icons.assignment_ind_outlined,
//                                           ),
//                                           label: const Text("Modify"),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.blue,
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 15,
//                                               vertical: 12,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                         ),
//                                         ElevatedButton.icon(
//                                           onPressed: () {
//                                             _showIssueDescriptionBottomSheet(
//                                               request,
//                                             );
//                                           },
//                                           icon: const Icon(Icons.visibility),
//                                           label: const Text("View"),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.green,
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 15,
//                                               vertical: 12,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _onAddMaintenanceRequest,
//         child: const Icon(Icons.add),
//         backgroundColor: Colors.teal,
//       ),
//     );
//   }
// }
