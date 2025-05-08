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
      showErrorDialog("Failed to load maintenance types. Please try again.");
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
      showErrorDialog("Failed to load staff for this maintenance type.");
    }
  }

  // Delete a staff-role assignment by staffId and roleId
  Future<void> deleteStaffById(int staffId, int roleId) async {
    final url = Uri.parse(
      '$kBaseurl/api/delete-staff-from-role/$staffId/$roleId/',
    );
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
            (staff) => staff['staffId'] == staffId && staff['roleId'] == roleId,
          );
        });
      } else {
        throw Exception('Failed to delete staff-role mapping');
      }
    } catch (e) {
      print("Error deleting staff-role: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting staff-role: $e")));
    }
  }

  // Confirm deletion of a staff-role assignment
  void _confirmDelete(BuildContext context, int staffId, int roleId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to delete this staff-role assignment?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await deleteStaffById(staffId, roleId); // Updated
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

  // Show error dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text("OK"),
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
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
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
                          final roleId = staff['roleId'];

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: AssetImage(
                                  'images/staff1.jpg', // Updated image path
                                ),
                                backgroundColor: Colors.grey[200],
                              ),

                              title: Text(
                                staffName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5E8D5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Role: $roleName",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 104, 64, 4),
                                  ),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDelete(context, staffId, roleId);
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
