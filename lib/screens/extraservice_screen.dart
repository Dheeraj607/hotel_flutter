import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/add_extraservice.dart';
import 'package:hotel_management/screens/updateextraservice.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExtraServiceScreens extends StatefulWidget {
  final int bookingId;

  const ExtraServiceScreens({super.key, required this.bookingId});

  @override
  State<ExtraServiceScreens> createState() => _ExtraServiceScreenState();
}

class _ExtraServiceScreenState extends State<ExtraServiceScreens> {
  List<dynamic> extraServices = [];
  Map<int, String> serviceCategories = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    await Future.wait([fetchServiceCategories(), fetchExtraServices()]);
  }

  Future<void> fetchServiceCategories() async {
    final url = Uri.parse("$kBaseurl/api/extra-service-categories/");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          serviceCategories = {
            for (var item in data) item['categoryId']: item['categoryName'],
          };
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
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
          isLoading = false;
        });
      } else {
        setState(() {
          extraServices = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final parsed = DateTime.parse(dateStr);
      return "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
    } catch (_) {
      return "Invalid Date";
    }
  }

  Widget buildPaymentDetails(List<dynamic> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          payments.map((payment) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.teal[50],
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.payments, color: Colors.teal[700]),
                title: Text(
                  "₹${payment['amount']} - ${payment['paymentMethod']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status: ${payment['paymentStatus']}",
                      style: TextStyle(color: Colors.teal[800]),
                    ),
                    Text("Date: ${_formatDate(payment['paymentDate'])}"),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget buildServiceCard(Map<String, dynamic> service) {
    final List<dynamic> payments = service['payment_details'] ?? [];
    final int? categoryId = service['categoryId'];
    final String categoryName = serviceCategories[categoryId] ?? 'Unknown';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.room_service, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service['serviceDetails'] ?? 'Unnamed Service',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.category, color: Colors.orange),
                const SizedBox(width: 6),
                Text("Category: $categoryName"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.green),
                const SizedBox(width: 6),
                Text("Cost: ₹${service['serviceCost'] ?? 'N/A'}"),
              ],
            ),
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                "Payments",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              buildPaymentDetails(payments),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => UpdateExtraServiceScreen(
                              serviceId: service['serviceId'],
                              serviceCost: service['serviceCost'],
                              bookingId: service['bookingId'],
                            ),
                      ),
                    );
                    fetchExtraServices();
                  },
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
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
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchInitialData,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
              : extraServices.isEmpty
              ? const Center(child: Text("No extra services found."))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: extraServices.length,
                itemBuilder:
                    (context, index) => buildServiceCard(extraServices[index]),
              ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Extra Service"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        AddExtraServiceScreen(bookingId: widget.bookingId),
              ),
            );
            fetchExtraServices();
          },
        ),
      ),
    );
  }
}
