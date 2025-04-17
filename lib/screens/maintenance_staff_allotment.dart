import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'add_staff_roles.dart'; // Make sure this file exists

class MaintenanceStaffAllotmentPage extends StatefulWidget {
  const MaintenanceStaffAllotmentPage({super.key});

  @override
  State<MaintenanceStaffAllotmentPage> createState() =>
      _MaintenanceStaffAllotmentPageState();
}

class _MaintenanceStaffAllotmentPageState
    extends State<MaintenanceStaffAllotmentPage> {
  List<dynamic> maintenanceTypes = [];
  dynamic selectedType;
  List<dynamic> staffList = [];

  @override
  void initState() {
    super.initState();
    fetchMaintenanceTypes();
  }

  // Fetch maintenance types from the API
  Future<void> fetchMaintenanceTypes() async {
    final url = Uri.parse('$kBaseurl/api/maintenance-types/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          maintenanceTypes = data;
        });
      } else {
        throw Exception('Failed to load maintenance types');
      }
    } catch (e) {
      print("Error fetching types: $e");
    }
  }

  // Fetch staff for the selected maintenance type
  Future<void> fetchStaffForType(int typeId) async {
    final url = Uri.parse('$kBaseurl/api/get-staffs/$typeId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          staffList = data;
        });
      } else {
        throw Exception('Failed to load staff for type $typeId');
      }
    } catch (e) {
      print("Error fetching staff: $e");
    }
  }

  // Delete a staff member by staffId
  Future<void> deleteStaffById(int staffId) async {
    final url = Uri.parse('$kBaseurl/api/delete-staff-by-type/$staffId/');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Deleted successfully'),
          ),
        );
        setState(() {
          staffList.removeWhere(
            (staff) => staff['staffId'] == staffId,
          ); // Remove deleted staff from list
        });
      } else {
        throw Exception('Failed to delete staff member');
      }
    } catch (e) {
      print("Error deleting staff: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting staff: $e")));
    }
  }

  // Confirm deletion of a staff member
  void _confirmDelete(BuildContext context, int staffId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to delete this staff member?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await deleteStaffById(
                    staffId,
                  ); // Call deleteStaffById with staffId
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
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
        title: const Text("Maintenance Staff Allotment"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton:
          selectedType != null
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AssignStaffPage(typeId: selectedType['typeId']),
                    ),
                  );
                  if (result == true) {
                    fetchStaffForType(selectedType['typeId']);
                  }
                },
                child: const Icon(Icons.add),
              )
              : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Filter by Maintenance Type',
                border: OutlineInputBorder(),
              ),
              value: selectedType,
              items:
                  maintenanceTypes.map<DropdownMenuItem<dynamic>>((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type['maintenanceTypeName']),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                  staffList = [];
                });
                fetchStaffForType(value['typeId']);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  staffList.isEmpty
                      ? const Center(child: Text('No staff available.'))
                      : ListView.builder(
                        itemCount: staffList.length,
                        itemBuilder: (context, index) {
                          final staff = staffList[index];
                          final staffName = staff['name'];
                          final roleName = staff['roleName'];
                          final staffId = staff['staffId'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(
                                staffName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text("Role: $roleName"),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDelete(
                                    context,
                                    staffId,
                                  ); // Pass staffId to delete
                                },
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
