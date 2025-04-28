import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PayServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const PayServiceScreen({super.key, required this.service});

  @override
  State<PayServiceScreen> createState() => _PayServiceScreenState();
}

class _PayServiceScreenState extends State<PayServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();

  String selectedPaymentMethod = 'Credit Card';
  String selectedPaymentType = 'Full Payment';
  DateTime selectedDate = DateTime.now();

  bool isSubmitting = false;

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final url = Uri.parse("$kBaseurl/api/payment_service/");
    final Map<String, dynamic> data = {
      "serviceId": widget.service['serviceId'], // ✅ FIXED
      "amount": double.tryParse(_amountController.text),
      "paymentMethod": selectedPaymentMethod,
      "transactionId": _transactionIdController.text.trim(),
      "paymentType": selectedPaymentType,
      "paymentDate": selectedDate.toUtc().toIso8601String(),
    };

    print("Sending data: $data"); // Optional: Debug print

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Payment successful')),
        );
        Navigator.pop(context); // Go back after successful payment
      } else {
        throw Exception("Failed to update payment");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.service['serviceCost'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pay for Service"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Service: ${widget.service['serviceDetails']}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount (₹)"),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Enter amount' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedPaymentMethod,
                decoration: const InputDecoration(labelText: "Payment Method"),
                items: const [
                  DropdownMenuItem(
                    value: "Credit Card",
                    child: Text("Credit Card"),
                  ),
                  DropdownMenuItem(value: "Cash", child: Text("Cash")),
                  DropdownMenuItem(value: "UPI", child: Text("UPI")),
                  DropdownMenuItem(value: "Online", child: Text("Online")),
                ],
                onChanged:
                    (value) => setState(() => selectedPaymentMethod = value!),
              ),
              TextFormField(
                controller: _transactionIdController,
                decoration: const InputDecoration(labelText: "Transaction ID"),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter transaction ID'
                            : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedPaymentType,
                decoration: const InputDecoration(labelText: "Payment Type"),
                items: const [
                  DropdownMenuItem(
                    value: "Full Payment",
                    child: Text("Full Payment"),
                  ),
                  DropdownMenuItem(value: "Advance", child: Text("Advance")),
                  DropdownMenuItem(
                    value: "Installment",
                    child: Text("Installment"),
                  ),
                ],
                onChanged:
                    (value) => setState(() => selectedPaymentType = value!),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(
                  "Payment Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickPaymentDate,
              ),
              const SizedBox(height: 20),
              isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: submitPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text("Submit Payment"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
