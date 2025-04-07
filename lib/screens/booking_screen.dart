import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'room_detail_screen.dart';

class BookRoomScreen extends StatefulWidget {
  final DateTime checkInDate;
  final Map<String, dynamic> roomData;

  const BookRoomScreen({
    super.key,
    required this.checkInDate,
    required this.roomData,
  });

  @override
  _BookRoomScreenState createState() => _BookRoomScreenState();
}

class _BookRoomScreenState extends State<BookRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passportController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController specialRequestsController =
      TextEditingController();
  final TextEditingController roomIdController = TextEditingController();
  final TextEditingController checkInDateController = TextEditingController();
  final TextEditingController advanceController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController paymentTypeController = TextEditingController();

  String? selectedPaymentMethod;
  String? selectedPaymentStatus;
  bool isLoading = false;
  DateTime? selectedCheckInDate;

  final List<String> paymentMethods = ["Credit Card", "Cash", "UPI", "Online"];
  final List<String> paymentStatuses = ["Pending", "Paid"];

  @override
  void initState() {
    super.initState();
    selectedCheckInDate = widget.checkInDate;
    checkInDateController.text = DateFormat(
      "yyyy-MM-dd",
    ).format(widget.checkInDate);

    // Autofill room details
    roomIdController.text = widget.roomData['id'].toString();
    advanceController.text = widget.roomData['Advance'].toString();
    rentController.text = widget.roomData['Rent'].toString();
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedCheckInDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedCheckInDate = picked;
        checkInDateController.text = DateFormat("yyyy-MM-dd").format(picked);
      });
    }
  }

  Future<void> bookRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url = Uri.parse("$kBaseurl/api/book-room/");
    final Map<String, dynamic> requestBody = {
      "customer_input": {
        "fullName": fullNameController.text.trim(),
        "idPassportNumber": passportController.text.trim(),
        "contactNumber": contactController.text.trim(),
        "emailAddress": emailController.text.trim(),
        "nationality": nationalityController.text.trim(),
        "specialRequests": specialRequestsController.text.trim(),
      },
      "roomId": int.tryParse(roomIdController.text) ?? 0,
      "checkInDate": DateFormat(
        "yyyy-MM-dd",
      ).format(selectedCheckInDate ?? DateTime.now()),
      "Advance": double.tryParse(advanceController.text) ?? 0.0,
      "Rent": double.tryParse(rentController.text) ?? 0.0,
      "payment": {
        "amount": double.tryParse(amountController.text) ?? 0.0,
        "paymentMethod": selectedPaymentMethod,
        "transactionId": transactionIdController.text.trim(),
        "paymentStatus": selectedPaymentStatus,
        "paymentType": paymentTypeController.text.trim(),
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        _showDialog("Success", "Room booked successfully!");
        clearFields();
      } else {
        _showDialog("Error", "Failed to book the room.");
      }
    } catch (error) {
      _showDialog("Network Error", "Could not connect to the server.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void clearFields() {
    fullNameController.clear();
    passportController.clear();
    contactController.clear();
    emailController.clear();
    nationalityController.clear();
    specialRequestsController.clear();
    roomIdController.clear();
    checkInDateController.clear();
    advanceController.clear();
    rentController.clear();
    amountController.clear();
    transactionIdController.clear();
    paymentTypeController.clear();
    selectedPaymentMethod = null;
    selectedPaymentStatus = null;
    selectedCheckInDate = null;
    setState(() {});
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book a Room"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCard(fullNameController, "Full Name"),
                _buildCard(passportController, "Passport ID"),
                _buildCard(contactController, "Contact Number"),
                _buildCard(emailController, "Email"),
                _buildCard(nationalityController, "Nationality"),
                _buildCard(specialRequestsController, "Special Requests"),
                _buildCard(roomIdController, "Room ID", isNumber: true),
                GestureDetector(
                  onTap: () => _selectCheckInDate(context),
                  child: AbsorbPointer(
                    child: _buildCard(checkInDateController, "Check-In Date"),
                  ),
                ),
                _buildCard(
                  advanceController,
                  "Advance Payment",
                  isNumber: true,
                ),
                _buildCard(rentController, "Total Rent", isNumber: true),
                _buildCard(amountController, "Payment Amount", isNumber: true),
                _buildDropdown(
                  "Payment Method",
                  paymentMethods,
                  selectedPaymentMethod,
                  (String? value) =>
                      setState(() => selectedPaymentMethod = value),
                ),
                _buildCard(transactionIdController, "Transaction ID"),
                _buildDropdown(
                  "Payment Status",
                  paymentStatuses,
                  selectedPaymentStatus,
                  (String? value) =>
                      setState(() => selectedPaymentStatus = value),
                ),
                _buildCard(paymentTypeController, "Payment Type"),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: bookRoom,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Book Room",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomDetailsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "View Room List",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
          ),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "$label is required";
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
          ),
          value: selectedValue,
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? "Please select $label" : null,
        ),
      ),
    );
  }
}
