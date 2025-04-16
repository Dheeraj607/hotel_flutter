import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IssueDescriptionScreen extends StatefulWidget {
  const IssueDescriptionScreen({
    super.key,
    required Map<String, dynamic> request,
    required String issueDescription,
    required requestId,
  });

  @override
  State<IssueDescriptionScreen> createState() => _IssueDescriptionScreenState();
}

class _IssueDescriptionScreenState extends State<IssueDescriptionScreen> {
  late Future<List<String>> _issueDescriptions;

  @override
  void initState() {
    super.initState();
    _issueDescriptions = fetchIssueDescriptions();
  }

  Future<List<String>> fetchIssueDescriptions() async {
    final response = await http.get(
      Uri.parse('$kBaseurl/api/maintenance-requests-with-staff/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map<String>((item) => item['issueDescription'] ?? 'No description')
          .toList();
    } else {
      throw Exception('Failed to load issue descriptions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Maintenance Issues'),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: FutureBuilder<List<String>>(
        future: _issueDescriptions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No maintenance issues found.',
                style: TextStyle(fontSize: 16),
              ),
            );
          } else {
            final descriptions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: descriptions.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.report_problem,
                      color: Colors.teal,
                    ),
                    title: Text(
                      descriptions[index],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    tileColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
