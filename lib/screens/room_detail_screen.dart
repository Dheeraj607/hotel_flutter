import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/extraservice_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({super.key});

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  List<dynamic> rooms = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRoomDetails();
  }

  Future<void> fetchRoomDetails() async {
    try {
      final response = await http.get(Uri.parse('$kBaseurl/api/room_details/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API Response: $data');

        // ✅ Filter only rooms that are occupied (i.e., have at least one booking)
        List<dynamic> occupiedRooms =
            data.where((room) {
              final bookings = room['bookings'];
              return bookings != null && bookings.isNotEmpty;
            }).toList();

        setState(() {
          rooms = occupiedRooms;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load room details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room Details')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) => RoomCard(room: rooms[index]),
              ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    var bookings = room['bookings'] ?? [];
    bool isOccupied = bookings.isNotEmpty;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Room No: ${room['roomNumber']}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOccupied ? Colors.redAccent : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOccupied ? "Occupied" : "Available",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Room Type: ${room['roomType']}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            if (isOccupied) CustomerDetails(bookings: bookings),
          ],
        ),
      ),
    );
  }
}

class CustomerDetails extends StatelessWidget {
  final List<dynamic> bookings;

  const CustomerDetails({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      debugPrint('No bookings found');
      return Text("No bookings available.");
    }

    var bookingData = bookings[0];
    debugPrint('Booking Data: $bookingData');

    int? bookingId = bookingData['bookingId'];
    if (bookingId == null) {
      debugPrint('Booking ID is null');
      return Text("Invalid booking data.");
    }

    List<dynamic> payments = bookingData['payment_details'] ?? [];
    List<dynamic> extraServices = bookingData['extra_services'] ?? [];

    Map<int, String> serviceMap = {
      for (var service in extraServices)
        service['serviceId']: service['serviceName'],
    };

    List<Map<String, dynamic>> enrichedPayments =
        payments.map<Map<String, dynamic>>((payment) {
          int? sid = payment['serviceId'];
          return {
            ...payment,
            'serviceName': sid != null ? (serviceMap[sid] ?? 'N/A') : 'N/A',
          };
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PaymentDetailsScreen(
                            paymentDetails: enrichedPayments,
                          ),
                    ),
                  );
                },
                icon: Icon(Icons.payment),
                label: Text("Payment Details"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('Passing Booking ID: $bookingId');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ExtraServiceScreen(bookingId: bookingId),
                    ),
                  );
                },
                icon: Icon(Icons.room_service),
                label: Text("Extra Service"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PaymentDetailsScreen extends StatelessWidget {
  final List<dynamic> paymentDetails;

  const PaymentDetailsScreen({super.key, required this.paymentDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment Details"),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: paymentDetails.length,
        itemBuilder: (context, index) {
          var payment = paymentDetails[index];
          String formattedDate = _formatDate(payment['paymentDate']);
          String serviceName = payment['serviceName'] ?? "N/A";
          String remarks =
              (payment['remarks'] != null &&
                      payment['remarks'].toString().toLowerCase() != 'null')
                  ? payment['remarks']
                  : "N/A";

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowWithIcon(
                      Icons.attach_money,
                      "Amount",
                      "\$${payment['amount']}",
                    ),
                    _rowWithIcon(
                      Icons.credit_card,
                      "Payment Method",
                      payment['paymentMethod'],
                    ),
                    _rowWithIcon(
                      Icons.check_circle,
                      "Status",
                      payment['paymentStatus'],
                    ),
                    _rowWithIcon(Icons.calendar_today, "Date", formattedDate),
                    _rowWithIcon(
                      Icons.room_service,
                      "Service Name",
                      serviceName,
                    ),
                    if (payment['inspectionId'] != null)
                      _rowWithIcon(Icons.notes, "Remarks", remarks),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat.yMMMMd().format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }
}


// class ExtraServiceScreen extends StatelessWidget {
//   final int bookingId;

//   const ExtraServiceScreen({super.key, required this.bookingId});

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('Received Booking ID: $bookingId'); // Debugging line
//     return Scaffold(
//       appBar: AppBar(title: const Text("Extra Services")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {},
//           child: const Text("Add Extra Service"),
//         ),
//       ),
//     );
//   }
// }

