import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/screens/modify_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hotel_management/constant.dart';

class AddMaintenanceRequestScreen extends StatefulWidget {
  final int roomId;
  final String roomNumber;
  final String roomType;
  final String status;

  const AddMaintenanceRequestScreen({
    super.key,
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.status,
  });

  @override
  State<AddMaintenanceRequestScreen> createState() =>
      _AddMaintenanceRequestScreenState();
}

class _AddMaintenanceRequestScreenState
    extends State<AddMaintenanceRequestScreen> {
  List<Map<String, dynamic>> maintenanceTypes = [];
  int? selectedTypeId;
  String issueDescription = '';
  String priorityLevel = 'Low';
  String status = 'Pending';
  DateTime selectedDate = DateTime.now();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String maintenanceTypeUrl = '$kBaseurl/api/maintenance-types/';
  final String requestApiUrl =
      '$kBaseurl/api/maintenance-request-with-assignment/';

  @override
  void initState() {
    super.initState();
    fetchMaintenanceTypes();
    print("Room ID: ${widget.roomId}");
  }

  Future<void> fetchMaintenanceTypes() async {
    try {
      final response = await http.get(Uri.parse(maintenanceTypeUrl));
      print('Fetching maintenance types from: $maintenanceTypeUrl');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          maintenanceTypes =
              data
                  .map(
                    (e) => {
                      'typeId': e['typeId'],
                      'maintenanceTypeName': e['maintenanceTypeName'],
                    },
                  )
                  .toList();
          print('Available maintenance types: $maintenanceTypes');
          if (maintenanceTypes.isNotEmpty && selectedTypeId == null) {
            selectedTypeId = maintenanceTypes[0]['typeId'];
          }
        });
      } else {
        throw Exception('Failed to load maintenance types');
      }
    } catch (e) {
      print('Error fetching maintenance types: $e');
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> submitRequest(bool bl) async {
    if (!_formKey.currentState!.validate() || selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final Map<String, dynamic> payload = {
      "roomId": widget.roomId,
      "issueDescription": issueDescription,
      "priorityLevel": priorityLevel,
      "status": status,
      "requestDate": DateFormat('yyyy-MM-dd').format(selectedDate),
      "maintenanceStaffId": null,
      "comments": "",
      "typeId": selectedTypeId,
    };

    try {
      print('Selected Type ID: $selectedTypeId');
      print('Submitting to: $requestApiUrl');
      print('Payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse(requestApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final resData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resData['message'] ?? 'Saved!')));
        if (bl) {
          Navigator.pop(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ModifyReqScreen(
                    reqid: resData['maintenanceRequest']['requestId'],
                    typeid: selectedTypeId,
                    roomId: widget.roomId.toString(), // Pass roomId as string
                    roomNumber: widget.roomNumber, // Pass roomNumber
                    roomType: widget.roomType, // Pass roomType
                    status: status, // Pass status
                  ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${resData['error'] ?? 'Error'}")),
        );
      }
    } catch (e) {
      print("Submission error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        widget.status.toLowerCase() == 'occupied' ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Maintenance Request Info"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 24),
              const Text(
                "Select Maintenance Type:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              maintenanceTypes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                    value: selectedTypeId,
                    items:
                        maintenanceTypes
                            .map(
                              (type) => DropdownMenuItem<int>(
                                value: type['typeId'],
                                child: Text(
                                  type['maintenanceTypeName']
                                      .toString()
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTypeId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null
                                ? 'Please select a maintenance type'
                                : null,
                  ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Issue Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => issueDescription = value,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priorityLevel,
                items:
                    ['Low', 'Medium', 'High']
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => priorityLevel = value);
                },
                decoration: const InputDecoration(
                  labelText: "Priority Level",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                items:
                    ['Pending', 'In Progress', 'Completed']
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => status = value);
                },
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: "Request Date",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(selectedDate),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save"),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          submitRequest(true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save and Assign"),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          submitRequest(false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
