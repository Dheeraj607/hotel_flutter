import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddExtraServiceScreen extends StatefulWidget {
  final int bookingId;

  AddExtraServiceScreen({super.key, required this.bookingId}) {
    print("Booking ID received in AddExtraServiceScreen: $bookingId");
  }

  @override
  _AddExtraServiceScreenState createState() => _AddExtraServiceScreenState();
}

class _AddExtraServiceScreenState extends State<AddExtraServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  String serviceName = '';
  double serviceCost = 0.0;
  String? paymentMethod;
  String? paymentType;
  DateTime? paymentDate;
  bool isPaid = false;

  List<String> paymentMethods = ['Credit Card', 'Cash', 'UPI', 'Online'];
  List<String> paymentTypes = ['Full Payment', 'Advance', 'Installment'];

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

    final extraService = {
      "bookingId": widget.bookingId,
      "extraServices": [
        {
          "serviceName": serviceName,
          "serviceCost": serviceCost,
          "payment":
              isPaid
                  ? {
                    "amount": serviceCost,
                    "paymentMethod": paymentMethod,
                    "paymentStatus": "Paid",
                    "paymentType": paymentType,
                    "paymentDate": paymentDate?.toIso8601String(),
                  }
                  : {"paymentStatus": "Pending"},
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse('$kBaseurl/api/payment_with_extras/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(extraService),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extra service added successfully')),
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
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Extra Service"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: _inputDecoration("Service Name"),
                validator:
                    (value) => value!.isEmpty ? "Enter service name" : null,
                onChanged: (value) => setState(() => serviceName = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration("Service Cost"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Enter service cost";
                  if (double.tryParse(value) == null)
                    return "Enter a valid number";
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    serviceCost = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text("Payment Done"),
                activeColor: Colors.teal,
                value: isPaid,
                onChanged: (value) => setState(() => isPaid = value),
              ),
              if (isPaid) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Payment Method"),
                  value: paymentMethod,
                  items:
                      paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                  onChanged: (value) => setState(() => paymentMethod = value),
                  validator:
                      (value) =>
                          value == null ? "Select a payment method" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Payment Type"),
                  value: paymentType,
                  items:
                      paymentTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                  onChanged: (value) => setState(() => paymentType = value),
                  validator:
                      (value) => value == null ? "Select a payment type" : null,
                ),
                const SizedBox(height: 16),
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
                  trailing: Icon(Icons.calendar_today, color: Colors.teal),
                  onTap: () => _selectPaymentDate(context),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: submitExtraService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
