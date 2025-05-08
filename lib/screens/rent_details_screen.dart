import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/CheckoutConfirmationPage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CalculateRentScreen extends StatefulWidget {
  final int bookingId;
  final Map<String, dynamic> roomDetails;

  const CalculateRentScreen({
    super.key,
    required this.bookingId,
    required this.roomDetails,
  });

  @override
  State<CalculateRentScreen> createState() => _CalculateRentScreenState();
}

class _CalculateRentScreenState extends State<CalculateRentScreen> {
  final TextEditingController checkoutDateController = TextEditingController();
  final TextEditingController checkoutTimeController = TextEditingController();
  final TextEditingController totalDaysStayedController =
      TextEditingController();
  final TextEditingController additionalChargesController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController stateGSTController = TextEditingController();
  final TextEditingController centralGSTController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController advancePaidController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();

  double rent = 0.0;
  double totalRent = 0.0;
  double additionalCharges = 0.0;
  double totalAmount = 0.0;
  double stateGST = 0.0;
  double centralGST = 0.0;
  double discount = 0.0;
  double advancePaid = 0.0;
  double finalAmount = 0.0;
  double totalAmountIncludingTax = 0.0;

  DateTime checkinDate = DateTime.now();
  DateTime checkoutDate = DateTime.now();
  String formattedCheckinTime = '';

  String? paymentMethod = 'Cash';
  String? paymentStatus = 'Pending';
  String? paymentType = 'Full';

  List<String> paymentMethodChoices = ['Credit Card', 'Cash', 'UPI', 'Online'];
  List<String> paymentStatusChoices = ['Pending', 'Paid'];
  List<String> paymentTypeChoices = ['Full', 'Partial'];

  @override
  void initState() {
    super.initState();
    rent = widget.roomDetails['Rent']?.toDouble() ?? 0.0;
    totalDaysStayedController.text = '1';
    advancePaid = widget.roomDetails['Advance']?.toDouble() ?? 0.0;
    advancePaidController.text = advancePaid.toString();

    // Parse check-in date
    String checkinDateStr = widget.roomDetails['checkinDate'] ?? '';
    if (checkinDateStr.isNotEmpty) {
      checkinDate = DateTime.parse(checkinDateStr);
    } else {
      checkinDate = DateTime.now(); // Fallback to current date if empty
    }

    // Parse check-in time
    String checkinTimeStr = widget.roomDetails['checkinTime'] ?? '';
    print('Raw checkinTime from roomDetails: $checkinTimeStr'); // Debug log

    if (checkinTimeStr.isNotEmpty) {
      try {
        final parsedTime = DateFormat('hh:mm a').parse(checkinTimeStr);
        formattedCheckinTime = DateFormat('hh:mm a').format(parsedTime);
        print('Parsed checkinTime: $formattedCheckinTime');
      } catch (e) {
        print('Error parsing check-in time: $e');
        // Fallback to current time or a default time
        formattedCheckinTime = DateFormat('hh:mm a').format(DateTime.now());
        print('Fallback checkinTime: $formattedCheckinTime');
      }
    } else {
      // Fallback for empty check-in time
      formattedCheckinTime = DateFormat('hh:mm a').format(DateTime.now());
      print('Empty checkinTime, using fallback: $formattedCheckinTime');
    }

    // Autofill checkoutTimeController with formattedCheckinTime
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkoutTimeController.text = formattedCheckinTime;
      print('Autofilled checkoutTimeController with: $formattedCheckinTime');
    });

    // Update state with formattedCheckinTime
    setState(() {
      this.formattedCheckinTime = formattedCheckinTime;
    });

    calculateTotalRent();
    calculateFinalAmount();
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  void calculateTotalRent() {
    final totalDaysStayed = int.tryParse(totalDaysStayedController.text) ?? 0;
    totalRent = totalDaysStayed * rent;
    calculateFinalAmount();
  }

  void calculateFinalAmount() {
    additionalCharges =
        double.tryParse(additionalChargesController.text) ?? 0.0;
    stateGST = double.tryParse(stateGSTController.text) ?? 0.0;
    centralGST = double.tryParse(centralGSTController.text) ?? 0.0;
    discount = double.tryParse(discountController.text) ?? 0.0;
    advancePaid = double.tryParse(advancePaidController.text) ?? 0.0;

    totalAmount = totalRent + additionalCharges;
    totalAmountIncludingTax = totalAmount + stateGST + centralGST;
    double discountAmount = (totalAmountIncludingTax * discount) / 100;
    finalAmount = totalAmountIncludingTax - discountAmount - advancePaid;

    setState(() {});
  }

  void calculateTotalDaysStayed() {
    if (checkoutDate.isAfter(checkinDate) ||
        checkoutDate.isAtSameMomentAs(checkinDate)) {
      final difference =
          checkoutDate.difference(checkinDate).inDays +
          1; // Include check-in day
      totalDaysStayedController.text = difference.toString();
      calculateTotalRent();
    }
  }

  Future<void> recordPayment() async {
    if (_validateFields()) {
      final url = Uri.parse("$kBaseurl/api/create_payment_checkout/");
      final body = {
        "bookingId": widget.bookingId,
        "amount": advancePaid,
        "paymentMethod": paymentMethod,
        "paymentStatus": paymentStatus,
        "paymentType": paymentType,
        "totalAmount": finalAmount,
        "stateGST": stateGST,
        "centralGST": centralGST,
        "transactionId": transactionIdController.text,
      };

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Payment Recorded!')));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CheckoutConfirmationPage(
                    bookingId: widget.bookingId,
                    roomNo: widget.roomDetails['roomNumber'] ?? 'N/A',
                    roomType: widget.roomDetails['roomType'] ?? 'N/A',
                    checkinDate: formatDate(checkinDate),
                    checkinTime: formattedCheckinTime,
                    checkoutDate: checkoutDateController.text,
                    checkoutTime: checkoutTimeController.text,
                    totalRent: totalRent,
                    additionalCharges: additionalCharges,
                    remarks: remarksController.text,
                    stateGST: stateGST,
                    centralGST: centralGST,
                    checkinAdvance: advancePaid,
                    finalAmount: finalAmount,
                    discount: discount,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to record payment. ${response.statusCode}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  bool _validateFields() {
    if (checkoutDateController.text.isEmpty ||
        checkoutTimeController.text.isEmpty ||
        totalDaysStayedController.text.isEmpty ||
        additionalChargesController.text.isEmpty ||
        stateGSTController.text.isEmpty ||
        centralGSTController.text.isEmpty ||
        discountController.text.isEmpty ||
        advancePaidController.text.isEmpty ||
        transactionIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all mandatory fields.')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    String roomNumber = widget.roomDetails['roomNumber'] ?? 'N/A';
    String roomType = widget.roomDetails['roomType'] ?? 'N/A';
    String formattedCheckinDate = formatDate(checkinDate);
    // // Debug print to verify values
    // print('build: formattedCheckinDate: $formattedCheckinDate');
    // print('build: formattedCheckinTime: $formattedCheckinTime');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Details Calculations'),
        backgroundColor: Colors.teal,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildCardDetails(
                  roomNumber,
                  roomType,
                  formattedCheckinDate,
                  formattedCheckinTime,
                ),
                const SizedBox(height: 20),
                buildDatePickerRow('Checkout Date:', checkoutDateController),
                const SizedBox(height: 10),
                buildTimePickerRow('Checkout Time:', checkoutTimeController),
                const SizedBox(height: 10),
                buildInputRow(
                  'Total Days Stayed:',
                  totalDaysStayedController,
                  calculateTotalRent,
                ),
                const SizedBox(height: 10),
                buildInputRow(
                  'Additional Charges:',
                  additionalChargesController,
                  calculateFinalAmount,
                ),
                const SizedBox(height: 10),
                buildInputRow('Remarks:', remarksController, null),
                const SizedBox(height: 20),
                Text('Total Rent: ₹$totalRent', style: boldTextStyle()),
                const SizedBox(height: 10),
                Text('Total Amount: ₹$totalAmount', style: boldTextStyle()),
                const SizedBox(height: 10),
                buildInputRow(
                  'State GST:',
                  stateGSTController,
                  calculateFinalAmount,
                ),
                const SizedBox(height: 10),
                buildInputRow(
                  'Central GST:',
                  centralGSTController,
                  calculateFinalAmount,
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Amount (Including Tax): ₹$totalAmountIncludingTax',
                  style: boldTextStyle(),
                ),
                const SizedBox(height: 10),
                buildInputRow(
                  'Discount:',
                  discountController,
                  calculateFinalAmount,
                ),
                const SizedBox(height: 10),
                buildInputRow(
                  'Advance Paid:',
                  advancePaidController,
                  calculateFinalAmount,
                ),
                const SizedBox(height: 20),
                Text(
                  'Final Amount: ₹$finalAmount',
                  style: boldTextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                buildDropdownRow(
                  'Payment Method:',
                  paymentMethodChoices,
                  paymentMethod,
                  (value) {
                    setState(() {
                      paymentMethod = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                buildDropdownRow(
                  'Payment Status:',
                  paymentStatusChoices,
                  paymentStatus,
                  (value) {
                    setState(() {
                      paymentStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                buildDropdownRow(
                  'Payment Type:',
                  paymentTypeChoices,
                  paymentType,
                  (value) {
                    setState(() {
                      paymentType = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                buildTextField('Transaction ID:', transactionIdController),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Record Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: recordPayment,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCardDetails(
    String roomNumber,
    String roomType,
    String checkin,
    String formattedCheckinTime,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Number: $roomNumber',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Room Type: $roomType',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Check-in Date: $checkin',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Check-in Time: $formattedCheckinTime',
              style: const TextStyle(fontSize: 16),
            ), // ✅ Added Time
          ],
        ),
      ),
    );
  }

  Widget buildDatePickerRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Select Date',
              icon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: checkoutDate,
                firstDate: DateTime.now(), // Set the first date to today's date
                lastDate: DateTime.now().add(
                  Duration(days: 365),
                ), // Optional: Set a max future date
              );
              if (selectedDate != null && selectedDate != checkoutDate) {
                setState(() {
                  checkoutDate = selectedDate;
                  controller.text = formatDate(checkoutDate);
                  calculateTotalDaysStayed();
                });
              }
            },
            readOnly: true,
          ),
        ),
      ],
    );
  }

  Widget buildTimePickerRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Select Time',
              icon: Icon(Icons.access_time),
            ),
            onTap: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(checkoutDate),
              );
              if (selectedTime != null) {
                setState(() {
                  checkoutDate = DateTime(
                    checkoutDate.year,
                    checkoutDate.month,
                    checkoutDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  controller.text = selectedTime.format(context);
                });
              }
            },
            readOnly: true,
          ),
        ),
      ],
    );
  }

  Widget buildInputRow(
    String label,
    TextEditingController controller,
    VoidCallback? onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter value'),
            keyboardType:
                label == 'Remarks:'
                    ? TextInputType
                        .text // Set TextInputType.text for remarks
                    : TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged != null ? (value) => onChanged() : null,
          ),
        ),
      ],
    );
  }

  Widget buildDropdownRow(
    String label,
    List<String> choices,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items:
                choices.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter transaction ID'),
          ),
        ),
      ],
    );
  }

  TextStyle boldTextStyle({double fontSize = 16}) {
    return TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);
  }
}
