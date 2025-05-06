import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/room_detail_screen.dart';
import 'package:hotel_management/screens/unpaidservice.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckoutConfirmationPage extends StatefulWidget {
  final String roomNo;
  final String roomType;
  final String checkinDate;
  final String checkinTime;
  final String checkoutDate;
  final String checkoutTime;
  final double totalRent;
  final double additionalCharges;
  final String remarks;
  final double stateGST;
  final double centralGST;
  final double checkinAdvance;
  final double finalAmount;
  final int bookingId;
  final double discount;

  const CheckoutConfirmationPage({
    super.key,
    required this.roomNo,
    required this.roomType,
    required this.checkinDate,
    required this.checkinTime,
    required this.checkoutDate,
    required this.checkoutTime,
    required this.totalRent,
    required this.additionalCharges,
    required this.remarks,
    required this.stateGST,
    required this.centralGST,
    required this.checkinAdvance,
    required this.finalAmount,
    required this.bookingId,
    required this.discount,
  });

  @override
  _CheckoutConfirmationPageState createState() =>
      _CheckoutConfirmationPageState();
}

class _CheckoutConfirmationPageState extends State<CheckoutConfirmationPage> {
  double extraserviceTotalAmount = 0.0;
  bool isLoading = false;
  double totalAmount = 0.0;
  double totalAmountIncludingTax = 0.0;
  double finalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    // extraserviceTotalAmount = 0.0;
    // totalAmount = 0.0;
    // totalAmountIncludingTax = 0.0;
    // finalAmount = 0.0;
    _fetchExtraServiceTotalAmount();
  }

  Future<void> _fetchExtraServiceTotalAmount() async {
    final response = await http.get(
      Uri.parse('$kBaseurl/api/extra-services/total/${widget.bookingId}/'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        extraserviceTotalAmount =
            (data['extraservicetotalAmount'] ?? 0).toDouble();
        _calculateAmounts(); // calculate as soon as data loads
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load extra service amount')),
      );
    }
  }

  void _calculateAmounts() {
    totalAmount =
        widget.totalRent + extraserviceTotalAmount + widget.additionalCharges;

    double stateGstAmount = (widget.stateGST / 100) * totalAmount;
    double centralGstAmount = (widget.centralGST / 100) * totalAmount;

    totalAmountIncludingTax = totalAmount + stateGstAmount + centralGstAmount;

    double discountAmount = (widget.discount / 100) * totalAmountIncludingTax;

    finalAmount =
        totalAmountIncludingTax - discountAmount - widget.checkinAdvance;
  }

  Future<void> _submitCheckout() async {
    setState(() {
      isLoading = true;
    });

    String formattedCheckinDate = _formatDate(widget.checkinDate);
    String formattedCheckoutDate = _formatDate(widget.checkoutDate);

    final checkoutData = {
      'bookingId': widget.bookingId,
      'roomNo': widget.roomNo,
      'roomType': widget.roomType,
      'checkinDate': formattedCheckinDate,
      'checkinTime': widget.checkinTime,
      'extraserviceTotalAmount': extraserviceTotalAmount,
      'checkoutDate': formattedCheckoutDate,
      'checkoutTime': widget.checkoutTime,
      'totalRent': widget.totalRent,
      'additionalCharges': widget.additionalCharges,
      'stateGST': widget.stateGST,
      'centralGST': widget.centralGST,
      'discount': widget.discount.toString(),
      'checkinAdvance': widget.checkinAdvance,
      'remarks': widget.remarks.isEmpty ? null : widget.remarks,
    };

    final response = await http.post(
      Uri.parse('$kBaseurl/api/checkout/create/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(checkoutData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      final checkoutId = data['checkoutId'];

      await _updateRoomStatusToUnoccupied(widget.roomNo);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout successful. Checkout ID: $checkoutId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 🎯 Now Navigate to RoomDetailsScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => RoomDetailsScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit checkout')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  String _formatDate(String date) {
    final parts = date.split('/');
    if (parts.length == 3) {
      return '${parts[0]}-${parts[1]}-${parts[2]}';
    }
    return date;
  }

  Future<void> _updateRoomStatusToUnoccupied(String roomNo) async {
    final updateRoomData = {'status': 'Unoccupied'};

    final response = await http.put(
      Uri.parse('$kBaseurl/api/rooms/$roomNo/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updateRoomData),
    );

    if (response.statusCode == 200) {
      print('Room status updated successfully.');
    } else {
      print('Failed to update room status.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Confirmation'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            buildDetailsCard(),
            const SizedBox(height: 20),
            buildConfirmationButton(),
            const SizedBox(height: 10),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            buildOkButton(),
          ],
        ),
      ),
    );
  }

  Widget buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTextDisplay('Room Number:', widget.roomNo),
            buildTextDisplay('Room Type:', widget.roomType),
            buildTextDisplay('Check-in Date:', widget.checkinDate),
            buildTextDisplay('Check-in Time:', widget.checkinTime),
            buildTextDisplay('Checkout Date:', widget.checkoutDate),
            buildTextDisplay('Checkout Time:', widget.checkoutTime),
            buildTextDisplay(
              'Total Rent:',
              '\$${widget.totalRent.toStringAsFixed(2)}',
            ),
            buildTextDisplay(
              'Additional Charges:',
              '\$${widget.additionalCharges.toStringAsFixed(2)}',
            ),
            buildTextDisplay('State GST:', '${widget.stateGST}%'),
            buildTextDisplay('Central GST:', '${widget.centralGST}%'),
            buildTextDisplay(
              'Check-in Advance:',
              '\$${widget.checkinAdvance.toStringAsFixed(2)}',
            ),
            buildTextDisplay(
              'Extra Service Amount:',
              '\$${extraserviceTotalAmount.toStringAsFixed(2)}',
            ),
            buildTextDisplay(
              'Total Amount:',
              '\$${totalAmount.toStringAsFixed(2)}',
            ),
            buildTextDisplay(
              'Total Amount Including Tax:',
              '\$${totalAmountIncludingTax.toStringAsFixed(2)}',
            ),
            buildTextDisplay(
              'Final Amount Payable:',
              '\$${finalAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextDisplay(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget buildConfirmationButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('Confirm Checkout'),
      ),
    );
  }

  Widget buildOkButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ExtraServicesScreen(
                    bookingId: widget.bookingId,
                    roomNo: widget.roomNo,
                    roomType: widget.roomType,
                    checkinDate: widget.checkinDate,
                    checkinTime: widget.checkinDate,
                    Rent: widget.totalRent,
                    Advance: widget.checkinAdvance,
                  ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('Cancel'),
      ),
    );
  }
}
