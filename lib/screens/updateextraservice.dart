import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/extraservice_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateExtraServiceScreen extends StatefulWidget {
  final int serviceId;
  final double serviceCost;
  final int bookingId;

  const UpdateExtraServiceScreen({
    super.key,
    required this.serviceId,
    required this.serviceCost,
    required this.bookingId,
  });

  @override
  State<UpdateExtraServiceScreen> createState() => _UpdatePaymentScreenState();
}

class _UpdatePaymentScreenState extends State<UpdateExtraServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _paymentTypeController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  String successMessage = "";

  String? selectedPaymentMethod;
  String? selectedPaymentType;
  DateTime? selectedPaymentDate;

  final List<String> paymentMethods = ["Credit Card", "Cash", "UPI", "Online"];
  final List<String> paymentTypes = ["Full Payment", "Advance", "Installment"];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.serviceCost.toString();
  }

  Future<void> updatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse("$kBaseurl/api/payment_service/");
    final Map<String, dynamic> paymentData = {
      "serviceId": widget.serviceId,
      "amount": double.parse(_amountController.text),
      "paymentMethod": selectedPaymentMethod,
      "transactionId": _transactionIdController.text,
      "paymentType": selectedPaymentType,
      "paymentDate":
          selectedPaymentDate != null
              ? "${selectedPaymentDate!.toIso8601String().split('T')[0]}T00:00:00"
              : null,
    };

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(paymentData),
      );

      if (response.statusCode == 200) {
        setState(() {
          successMessage = "Payment updated successfully!";
          errorMessage = null;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ExtraServiceScreens(bookingId: widget.bookingId),
          ),
        );
      } else {
        setState(() {
          errorMessage = "Error ${response.statusCode}: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to update payment: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedPaymentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedPaymentDate = pickedDate;
        _paymentDateController.text =
            "${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Payment"),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: "Amount (₹)",
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter an amount";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPaymentMethod = newValue;
                    });
                  },
                  items:
                      paymentMethods.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  decoration: const InputDecoration(
                    labelText: "Payment Method",
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return "Please select a payment method";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _transactionIdController,
                  decoration: const InputDecoration(
                    labelText: "Transaction ID",
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter transaction ID";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentType,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPaymentType = newValue;
                    });
                  },
                  items:
                      paymentTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  decoration: const InputDecoration(
                    labelText: "Payment Type",
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return "Please select a payment type";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentDateController,
                  decoration: const InputDecoration(
                    labelText: "Payment Date",
                    suffixIcon: Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  readOnly: true,
                  onTap: pickDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter payment date";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (successMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        successMessage,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  Center(
                    child: ElevatedButton(
                      onPressed: updatePayment,
                      child: const Text("Update Payment"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          84,
                          207,
                          187,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
