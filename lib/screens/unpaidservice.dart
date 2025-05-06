import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/add_extraservice.dart';
import 'package:hotel_management/screens/payservicescreen.dart';
import 'package:hotel_management/screens/rent_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExtraServicesScreen extends StatefulWidget {
  final int bookingId;
  final String roomNo;
  final String roomType;
  final String checkinDate;
  final String checkinTime;
  final double Rent;
  final double Advance;

  const ExtraServicesScreen({
    Key? key,
    required this.bookingId,
    required this.roomNo,
    required this.roomType,
    required this.checkinDate,
    required this.checkinTime,
    required this.Rent,
    required this.Advance,
  }) : super(key: key);

  @override
  State<ExtraServicesScreen> createState() => _ExtraServicesScreenState();
}

class _ExtraServicesScreenState extends State<ExtraServicesScreen> {
  bool isLoading = true;
  bool isCategoriesLoading = true;
  List<dynamic> extraServices = [];
  List<dynamic> categories = [];

  bool areAllServicesPaid() {
    return extraServices.isNotEmpty &&
        extraServices.every((service) => service['paymentStatus'] == "Paid");
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final url = "$kBaseurl/api/extra-service-categories/";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> categoryList = json.decode(response.body);
        setState(() {
          categories = categoryList;
          isCategoriesLoading = false;
        });
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      setState(() => isCategoriesLoading = false);
    }
  }

  Future<void> fetchData() async {
    final url = "$kBaseurl/api/extra_services/?bookingId=${widget.bookingId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> services = json.decode(response.body);
        services.sort((a, b) {
          var statusA = a['paymentStatus'];
          var statusB = b['paymentStatus'];
          return statusA == "Unpaid" ? -1 : (statusB == "Unpaid" ? 1 : 0);
        });
        setState(() {
          extraServices = services;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load extra services");
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String getCategoryName(int categoryId) {
    final category = categories.firstWhere(
      (cat) => cat['categoryId'] == categoryId,
      orElse: () => {'categoryName': 'Unknown'},
    );
    return category['categoryName'] ?? 'Unknown';
  }

  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  void updatePaymentStatus(int serviceId) {
    setState(() {
      final index = extraServices.indexWhere(
        (service) => service['id'] == serviceId,
      );
      if (index != -1) {
        extraServices[index]['paymentStatus'] = "Paid";
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      isCategoriesLoading = true;
    });
    await fetchCategories();
    await fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Extra Services",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),

        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AddExtraServiceScreen(bookingId: widget.bookingId),
                ),
              );
              if (result == true) await _onRefresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child:
                  isLoading || isCategoriesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : extraServices.isEmpty
                      ? const Center(
                        child: Text(
                          "No extra services found.",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: extraServices.length,
                        itemBuilder: (context, index) {
                          final service = extraServices[index];
                          final paymentDetails =
                              service['payment_details']?.isNotEmpty == true
                                  ? service['payment_details'][0]
                                  : null;
                          final paymentStatus = service['paymentStatus'];
                          final serviceDetails = service['serviceDetails'];
                          final serviceCost = service['serviceCost'];
                          final categoryName = getCategoryName(
                            service['categoryId'],
                          );

                          String paymentMethod = "";
                          String paymentDate = "";
                          String paymentInfo = "Status: $paymentStatus";
                          Color statusColor = Colors.red;

                          if (paymentStatus == "Paid" &&
                              paymentDetails != null) {
                            paymentMethod =
                                paymentDetails['paymentMethod'] ?? "N/A";
                            paymentDate = formatDate(
                              paymentDetails['paymentDate'] ?? "",
                            );
                            paymentInfo =
                                "Paid via $paymentMethod on $paymentDate";
                            statusColor = Colors.green[700]!;
                          } else {
                            paymentInfo = "Pending Payment";
                          }

                          return Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal,
                                        ),
                                      ),
                                      if (paymentStatus == "Unpaid")
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.payment),
                                          label: const Text("Pay"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => PayServiceScreen(
                                                      service: service,
                                                    ),
                                              ),
                                            );
                                            if (result != null)
                                              updatePaymentStatus(
                                                service['id'],
                                              );
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    serviceDetails,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Cost: ₹$serviceCost",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    paymentInfo,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Confirm and Calculate Rent"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (areAllServicesPaid() || extraServices.isEmpty)
                          ? Colors.teal
                          : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (areAllServicesPaid() || extraServices.isEmpty)
                        ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CalculateRentScreen(
                                    bookingId: widget.bookingId,
                                    roomDetails: {
                                      'roomNumber': widget.roomNo,
                                      'roomType': widget.roomType,
                                      'checkinDate': widget.checkinDate,
                                      'checkinTime': widget.checkinTime,
                                      'Rent': widget.Rent,
                                      'Advance': widget.Advance,
                                    },
                                  ),
                            ),
                          );
                        }
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
