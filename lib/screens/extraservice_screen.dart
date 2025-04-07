import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/add_extraservice.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExtraServiceScreen extends StatefulWidget {
  final int bookingId;

  const ExtraServiceScreen({super.key, required this.bookingId});

  @override
  State<ExtraServiceScreen> createState() => _ExtraServiceScreenState();
}

class _ExtraServiceScreenState extends State<ExtraServiceScreen> {
  List<dynamic> extraServices = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchExtraServices();
  }

  Future<void> fetchExtraServices() async {
    final url = Uri.parse(
      "$kBaseurl/api/extra_services/?bookingId=${widget.bookingId}",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          extraServices = data;
          error = null;
          isLoading = false;
        });
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        // No services found, but not an error
        setState(() {
          extraServices = [];
          error = null;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to fetch services (Status: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error occurred: $e";
        isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final parsed = DateTime.parse(dateStr);
      return "${parsed.day}-${parsed.month}-${parsed.year}";
    } catch (e) {
      return "Invalid Date";
    }
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    final List<dynamic> payments = service['payment_details'] ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service['serviceName'] ?? 'Unnamed Service',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18, color: Colors.teal),
                const SizedBox(width: 4),
                Text("Cost: ₹${service['serviceCost'] ?? 'N/A'}"),
              ],
            ),
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(thickness: 1),
              const Text(
                "Payments:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...payments.map((payment) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payment,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${payment['amount']} - ${payment['paymentMethod']}",
                            ),
                            Text("Status: ${payment['paymentStatus']}"),
                            Text(
                              "Date: ${_formatDate(payment['paymentDate'])}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extra Services"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
                : extraServices.isEmpty
                ? const SizedBox.shrink() // Blank screen when no services
                : ListView.builder(
                  itemCount: extraServices.length,
                  itemBuilder:
                      (context, index) =>
                          buildServiceCard(extraServices[index]),
                ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        AddExtraServiceScreen(bookingId: widget.bookingId),
              ),
            );
            fetchExtraServices(); // Refresh after adding service
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add Extra Service",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
