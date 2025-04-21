import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../constant.dart'; // Update path if needed

class AssignStaffPage extends StatefulWidget {
  const AssignStaffPage({Key? key, required this.typeId}) : super(key: key);

  final int typeId;

  @override
  State<AssignStaffPage> createState() => _AssignStaffPageState();
}

class _AssignStaffPageState extends State<AssignStaffPage> {
  List<dynamic> roles = [];
  List<dynamic> availableStaff = [];
  dynamic selectedRole;
  dynamic selectedStaff;

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  // Fetch roles for the dropdown
  Future<void> fetchRoles() async {
    final url = Uri.parse('$kBaseurl/api/maintenance-roles/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          roles = json.decode(response.body) ?? [];
          print('Roles fetched: $roles');
        });
      } else {
        throw Exception('Failed to load roles');
      }
    } catch (e) {
      print("Error fetching roles: $e");
    }
  }

  // Fetch staff who are not assigned to a specific role
  Future<void> fetchStaffNotInRole(int roleId) async {
    final url = Uri.parse('$kBaseurl/api/get_staff_not_in_role/$roleId/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          availableStaff = json.decode(response.body) ?? [];
          print('Available staff fetched: $availableStaff');
          selectedStaff = null; // reset selected staff on role change
        });
      } else {
        throw Exception('Failed to load staff');
      }
    } catch (e) {
      print("Error fetching staff: $e");
    }
  }

  // Assign the selected staff to the selected role
  Future<void> assignStaffToRole() async {
    if (selectedRole == null || selectedStaff == null) return;

    final url = Uri.parse('$kBaseurl/api/maintenance-staff/');
    final body = json.encode({
      "staffId": selectedStaff['staffId'],
      "roleId": selectedRole['roleId'],
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff successfully assigned')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to assign staff');
      }
    } catch (e) {
      print("Error assigning staff: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Staff to Role")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for selecting role
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(),
              ),
              value: selectedRole ?? (roles.isNotEmpty ? roles[0] : null),
              items:
                  roles.map<DropdownMenuItem<dynamic>>((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role['roleName']),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                  availableStaff = []; // Reset available staff list
                  selectedStaff = null; // Reset selected staff
                });
                if (value != null) {
                  fetchStaffNotInRole(value['roleId']);
                }
              },
            ),
            const SizedBox(height: 20),

            // Dropdown for selecting staff
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Select Staff',
                border: OutlineInputBorder(),
              ),
              value:
                  selectedStaff ??
                  (availableStaff.isNotEmpty ? availableStaff[0] : null),
              items:
                  availableStaff.isNotEmpty
                      ? availableStaff.map<DropdownMenuItem<dynamic>>((staff) {
                        return DropdownMenuItem(
                          value: staff,
                          child: Text(
                            staff['staffName'],
                          ), // Ensure staffName exists
                        );
                      }).toList()
                      : [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No staff available'),
                        ),
                      ],
              onChanged: (value) {
                setState(() {
                  selectedStaff = value;
                });
              },
            ),
            const SizedBox(height: 30),

            // Save button to assign staff to role
            ElevatedButton(
              onPressed: assignStaffToRole,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
