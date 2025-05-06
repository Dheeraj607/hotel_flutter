import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/CheckoutDetailScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckoutReportScreen extends StatefulWidget {
  const CheckoutReportScreen({super.key});

  @override
  State<CheckoutReportScreen> createState() => _CheckoutReportScreenState();
}

class _CheckoutReportScreenState extends State<CheckoutReportScreen> {
  List<dynamic> _checkoutReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCheckoutReports();
  }

  Future<void> fetchCheckoutReports() async {
    final url = Uri.parse("$kBaseurl/api/checkouts/");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _checkoutReports = data;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load checkout reports");
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              "Room No: ${report['roomNo']} (${report['roomType']})",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.login, color: Colors.green, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Check-in: ${report['checkinDate']} at ${report['checkinTime']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Check-out: ${report['checkoutDate']} at ${report['checkoutTime']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Final Amount: ₹${report['finalAmount']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CheckoutDetailScreen(report: report),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text("View Details"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Checkout Reports",
          // style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _checkoutReports.isEmpty
              ? const Center(child: Text("No checkout reports found"))
              : ListView.builder(
                itemCount: _checkoutReports.length,
                itemBuilder: (context, index) {
                  return buildReportCard(_checkoutReports[index]);
                },
              ),
    );
  }
}
