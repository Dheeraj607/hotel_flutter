import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/add_extraservice.dart';
import 'package:hotel_management/screens/payservicescreen.dart';
import 'package:hotel_management/screens/room_detail_screen.dart'; // Import the CalculateRentScreen
import 'package:hotel_management/screens/rent_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
      print("Error fetching categories: $e");
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
      print("Error fetching extra services: $e");
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
      final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      return dateFormat.format(parsedDate);
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
    print(
      "Check-in Time: ${widget.checkinTime}",
    ); // Check if the value is correct
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extra Services"),
        backgroundColor: Colors.teal,
        elevation: 0,
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
              if (result == true) {
                await _onRefresh();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child:
                      isLoading || isCategoriesLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount:
                                extraServices.isEmpty
                                    ? 1
                                    : extraServices
                                        .length, // Handle empty list case
                            itemBuilder: (context, index) {
                              if (extraServices.isEmpty) {
                                return Center(
                                  child: Text("No extra services available"),
                                );
                              }
                              final service = extraServices[index];
                              final paymentDetails =
                                  service['payment_details']?.isNotEmpty == true
                                      ? service['payment_details'][0]
                                      : null; // Check if payment_details is non-empty
                              final paymentStatus = service['paymentStatus'];
                              final serviceDetails = service['serviceDetails'];
                              final serviceCost = service['serviceCost'];
                              final categoryId = service['categoryId'];
                              final categoryName = getCategoryName(categoryId);

                              String paymentMethod = "";
                              String paymentDate = "";
                              String paymentInfo = "Status: $paymentStatus";
                              Color paymentStatusColor =
                                  paymentStatus == "Paid"
                                      ? Colors.green
                                      : Colors.red;

                              if (paymentStatus == "Paid" &&
                                  paymentDetails != null) {
                                paymentMethod =
                                    paymentDetails['paymentMethod'] ??
                                    "Unknown";
                                paymentDate =
                                    paymentDetails['paymentDate'] ?? "Unknown";
                                paymentDate = formatDate(paymentDate);
                                paymentInfo =
                                    "Status: Paid\nMethod: $paymentMethod\nDate: $paymentDate";
                              } else if (paymentStatus == "Unpaid") {
                                paymentInfo = "Status: Pending";
                              }

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            categoryName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                          if (paymentStatus == "Unpaid")
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                final updatedService =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                PayServiceScreen(
                                                                  service:
                                                                      service,
                                                                ),
                                                      ),
                                                    );
                                                if (updatedService != null) {
                                                  updatePaymentStatus(
                                                    service['id'],
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.payment),
                                              label: const Text("Pay"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
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
                                          color: paymentStatusColor,
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
                    onPressed:
                        areAllServicesPaid() || extraServices.isEmpty
                            ? () {
                              String roomNo = widget.roomNo;
                              String roomType = widget.roomType;
                              String checkinDate = widget.checkinDate;
                              String checkinTime = widget.checkinTime;
                              double Rent = widget.Rent;
                              double Advance = widget.Advance;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CalculateRentScreen(
                                        bookingId: widget.bookingId,
                                        roomDetails: {
                                          'roomNumber': roomNo,
                                          'roomType': roomType,
                                          'checkinDate': checkinDate,
                                          'checkinTime': checkinTime,
                                          'Rent': Rent,
                                          'Advance': Advance,
                                        },
                                      ),
                                ),
                              );
                            }
                            : null,
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
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
