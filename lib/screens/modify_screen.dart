import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/maintenance_request_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ModifyReqScreen extends StatefulWidget {
  final int reqid;
  final int? typeid;
  final String roomId;
  final String roomNumber;
  final String roomType;
  final String status;

  const ModifyReqScreen({
    super.key,
    required this.reqid,
    required this.typeid,
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.status,
  });

  @override
  State<ModifyReqScreen> createState() => _ModifyReqScreenState();
}

class _ModifyReqScreenState extends State<ModifyReqScreen> {
  List<Map<String, dynamic>> staffList = [];
  int? selectedStaffId;
  bool isLoading = false;
  late final TextEditingController commentController;
  late final TextEditingController dateController;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    dateController = TextEditingController(
      text: _dateFormat.format(DateTime.now()),
    );
    fetchStaffs();
  }

  @override
  void dispose() {
    commentController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> fetchStaffs() async {
    final url = Uri.parse('$kBaseurl/api/get-staffs/${widget.typeid}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        staffList = data.cast<Map<String, dynamic>>();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load staff list')),
      );
    }
  }

  Future<void> modifyAssignment() async {
    if (selectedStaffId == null || commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff and enter comments'),
        ),
      );
      return;
    }

    final url = Uri.parse('$kBaseurl/api/modify-assignment/');
    final body = json.encode({
      "requestId": widget.reqid,
      "staffId": selectedStaffId,
      "comments": commentController.text.trim(),
      "assignedDate": dateController.text.trim(),
    });

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment modified successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => MaintenanceRequestScreen(
                roomId: widget.roomId,
                roomNumber: widget.roomNumber,
                roomType: widget.roomType,
                status: widget.status,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to modify assignment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modify Assignment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Select Staff",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: selectedStaffId,
                        items:
                            staffList.map((staff) {
                              return DropdownMenuItem<int>(
                                value: staff['maintenanceStaffId'],
                                child: Text(staff['name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStaffId = value;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Assigned Date",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              dateController.text = _dateFormat.format(
                                pickedDate,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text("Comments", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter comments',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: modifyAssignment,
                          child: const Text("Submit"),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
