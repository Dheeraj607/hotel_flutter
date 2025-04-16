import 'package:flutter/material.dart';

class IssueDescriptionScreen extends StatelessWidget {
  final int requestId; // requestId to be passed
  final String issueDescription; // issueDescription to be passed

  const IssueDescriptionScreen({
    super.key,
    required this.requestId, // Add the requestId here
    required this.issueDescription, // Add the issueDescription here
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Maintenance Request Detail")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request ID: $requestId'),
            const SizedBox(height: 10),
            Text('Issue Description: $issueDescription'),
          ],
        ),
      ),
    );
  }
}
