import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model for Extra Service Category
class ExtraServiceCategory {
  final int categoryId;
  final String categoryName;

  ExtraServiceCategory({required this.categoryId, required this.categoryName});

  factory ExtraServiceCategory.fromJson(Map<String, dynamic> json) {
    return ExtraServiceCategory(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
    );
  }
}

class AddExtraServiceScreen extends StatefulWidget {
  final int bookingId;

  const AddExtraServiceScreen({super.key, required this.bookingId});

  @override
  State<AddExtraServiceScreen> createState() => _AddExtraServiceScreenState();
}

class _AddExtraServiceScreenState extends State<AddExtraServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  String serviceDetails = '';
  int? selectedCategoryId;
  double serviceCost = 0.0;
  double paidAmount = 0.0;
  String? paymentMethod;
  String? paymentType;
  DateTime? paymentDate;
  String transactionId = '';
  bool isPaid = false;

  List<String> paymentMethods = ['Credit Card', 'Cash', 'UPI', 'Online'];
  List<String> paymentTypes = ['Full Payment', 'Advance', 'Installment'];

  List<ExtraServiceCategory> categoryList = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    fetchServiceCategories();
  }

  Future<void> fetchServiceCategories() async {
    final url = Uri.parse("$kBaseurl/api/extra-service-categories/");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          categoryList =
              data.map((item) => ExtraServiceCategory.fromJson(item)).toList();
          isLoadingCategories = false;
          if (categoryList.isNotEmpty && selectedCategoryId == null) {
            selectedCategoryId = categoryList.first.categoryId;
          }
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != paymentDate) {
      setState(() {
        paymentDate = pickedDate;
      });
    }
  }

  Future<void> submitExtraService() async {
    if (!_formKey.currentState!.validate()) return;

    String categoryName =
        categoryList
            .firstWhere(
              (category) => category.categoryId == selectedCategoryId,
              orElse:
                  () => ExtraServiceCategory(
                    categoryId: 0,
                    categoryName: 'Unknown',
                  ),
            )
            .categoryName;

    // Determine payment status
    String paymentStatus = "Pending";
    if (isPaid && paidAmount > 0) {
      if (paidAmount >= serviceCost) {
        paymentStatus = "Paid";
      } else {
        paymentStatus = "Partially Paid";
      }
    }

    // Build extra service map
    Map<String, dynamic> extraServiceEntry = {
      "categoryId": selectedCategoryId,
      "categoryName": categoryName,
      "serviceDetails": serviceDetails,
      "serviceCost": serviceCost,
    };

    // Only add payment if it was made
    if (isPaid && paidAmount > 0) {
      extraServiceEntry["payment"] = {
        "amount": paidAmount,
        "paymentMethod": paymentMethod,
        "paymentStatus": paymentStatus,
        "paymentType": paymentType,
        "transactionId": transactionId,
        "paymentDate": paymentDate?.toIso8601String(),
      };
    }

    final extraServicePayload = {
      "bookingId": widget.bookingId,
      "extraServices": [extraServiceEntry],
    };

    try {
      final response = await http.post(
        Uri.parse('$kBaseurl/api/payment_with_extras/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(extraServicePayload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extra service added successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.teal, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Extra Service"),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
        // foregroundColor: Colors.white,
        elevation: 5,
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
        // ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   "Add New Extra Service",
              //   style: TextStyle(
              //     fontSize: 24,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.teal,
              //   ),
              // ),
              const SizedBox(height: 20),

              // Service Details Input
              TextFormField(
                decoration: _inputDecoration("Service Details"),
                validator:
                    (value) => value!.isEmpty ? "Enter service details" : null,
                onChanged: (value) => setState(() => serviceDetails = value),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                    decoration: _inputDecoration("Service Category"),
                    value: selectedCategoryId,
                    items:
                        categoryList
                            .map(
                              (category) => DropdownMenuItem<int>(
                                value: category.categoryId,
                                child: Text(category.categoryName),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() => selectedCategoryId = value),
                    validator:
                        (value) =>
                            value == null ? "Select a service category" : null,
                  ),
              const SizedBox(height: 16),

              // Service Cost Input
              TextFormField(
                decoration: _inputDecoration("Service Cost"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Enter service cost";
                  if (double.tryParse(value) == null) {
                    return "Enter a valid number";
                  }
                  return null;
                },
                onChanged:
                    (value) => setState(
                      () => serviceCost = double.tryParse(value) ?? 0.0,
                    ),
              ),
              const SizedBox(height: 16),

              // Payment Switch
              SwitchListTile(
                title: const Text(
                  "Payment Done",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                activeColor: Colors.teal,
                value: isPaid,
                onChanged: (value) => setState(() => isPaid = value),
              ),

              if (isPaid) ...[
                const SizedBox(height: 16),
                // Paid Amount Input
                TextFormField(
                  decoration: _inputDecoration("Amount Paid"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return "Enter paid amount";
                    if (double.tryParse(value) == null) {
                      return "Enter a valid number";
                    }
                    return null;
                  },
                  onChanged:
                      (value) => setState(
                        () => paidAmount = double.tryParse(value) ?? 0.0,
                      ),
                ),
                const SizedBox(height: 16),

                // Transaction ID Input
                TextFormField(
                  decoration: _inputDecoration("Transaction ID"),
                  validator:
                      (value) => value!.isEmpty ? "Enter transaction ID" : null,
                  onChanged: (value) => setState(() => transactionId = value),
                ),
                const SizedBox(height: 16),

                // Payment Method Dropdown
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Payment Method"),
                  value: paymentMethod,
                  items:
                      paymentMethods
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => paymentMethod = value),
                  validator:
                      (value) =>
                          value == null ? "Select a payment method" : null,
                ),
                const SizedBox(height: 16),

                // Payment Type Dropdown
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Payment Type"),
                  value: paymentType,
                  items:
                      paymentTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => paymentType = value),
                  validator:
                      (value) => value == null ? "Select a payment type" : null,
                ),
                const SizedBox(height: 16),

                // Payment Date Selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    paymentDate == null
                        ? "Select Payment Date"
                        : "Payment Date: ${paymentDate!.day}-${paymentDate!.month}-${paymentDate!.year}",
                    style: TextStyle(
                      color: paymentDate == null ? Colors.grey : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: Colors.teal,
                  ),
                  onTap: () => _selectPaymentDate(context),
                ),
              ],

              const SizedBox(height: 30),

              // Submit Button
              Center(
                child: Container(
                  width: 200, // Make the button take full width
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: submitExtraService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
