import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/extraservice_screen.dart';
import 'package:hotel_management/screens/unpaidservice.dart';
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

        // Filter rooms where status is "Occupied"
        List<dynamic> occupiedRooms =
            data.where((room) {
              return room['status'] != null && room['status'] == 'Occupied';
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

  Future<void> handleRefresh() async {
    setState(() {
      isLoading = true;
    });
    await fetchRoomDetails();
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
              : RefreshIndicator(
                onRefresh: handleRefresh,
                child: ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder:
                      (context, index) => RoomCard(
                        room: rooms[index],
                        onDataChanged: handleRefresh,
                      ),
                ),
              ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onDataChanged;

  const RoomCard({super.key, required this.room, required this.onDataChanged});

  @override
  Widget build(BuildContext context) {
    var bookings = room['bookings'] ?? [];
    bool isOccupied = room['status'] != null && room['status'] == 'Occupied';

    // Parsing Rent and Advance to double
    double Rent = double.tryParse(room['Rent'].toString()) ?? 0.0;
    double Advance = double.tryParse(room['Advance'].toString()) ?? 0.0;

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
                  "Room No: ${room['roomNumber'] ?? 'N/A'}",
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
              "Room Type: ${room['roomType'] ?? 'N/A'}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            if (isOccupied)
              CustomerDetails(bookings: bookings, onDataChanged: onDataChanged),
            SizedBox(height: 12),
            if (isOccupied)
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ExtraServicesScreen(
                            bookingId: int.parse(
                              bookings[0]['bookingId'].toString(),
                            ),
                            roomNo: room['roomNumber'].toString(),
                            roomType: room['roomType'].toString(),
                            checkinDate: bookings[0]['checkInDate'].toString(),
                            checkinTime: bookings[0]['checkInTime'].toString(),
                            Rent: Rent,
                            Advance: Advance,
                          ),
                    ),
                  );
                  onDataChanged();
                },
                icon: Icon(Icons.exit_to_app),
                label: Text("Checkout"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomerDetails extends StatelessWidget {
  final List<dynamic> bookings;
  final VoidCallback onDataChanged;

  const CustomerDetails({
    super.key,
    required this.bookings,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return Text("No bookings available.");
    var bookingData = bookings[0];
    int? bookingId = bookingData['bookingId'];
    if (bookingId == null) return Text("Invalid booking data.");

    List<dynamic> payments = bookingData['payment_details'] ?? [];
    List<dynamic> extraServices = bookingData['extra_services'] ?? [];

    Map<int, String> serviceMap = {
      for (var service in extraServices)
        service['serviceId']: service['serviceName'] ?? 'N/A',
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PaymentDetailsScreen(
                            paymentDetails: enrichedPayments,
                          ),
                    ),
                  );
                  onDataChanged();
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ExtraServiceScreens(bookingId: bookingId),
                    ),
                  );
                  onDataChanged();
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

class PaymentDetailsScreen extends StatefulWidget {
  final List<dynamic> paymentDetails;

  const PaymentDetailsScreen({super.key, required this.paymentDetails});

  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  Map<int, String> serviceCategoryMap = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryNames();
  }

  Future<void> _loadCategoryNames() async {
    for (var payment in widget.paymentDetails) {
      int? serviceId = payment['serviceId'];
      if (serviceId != null && !serviceCategoryMap.containsKey(serviceId)) {
        String categoryName = await _fetchCategoryName(serviceId);
        setState(() {
          serviceCategoryMap[serviceId] = categoryName;
        });
      }
    }
  }

  Future<String> _fetchCategoryName(int serviceId) async {
    try {
      final url = Uri.parse("$kBaseurl/api/get-category-name/$serviceId/");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['categoryName'] ?? 'No Category Name';
      } else if (response.statusCode == 404) {
        return 'Category not found';
      } else {
        return 'Failed (Status: ${response.statusCode})';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == 'null') return "N/A";
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd – kk:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Details"),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: widget.paymentDetails.length,
        itemBuilder: (context, index) {
          var payment = widget.paymentDetails[index];
          String formattedDate = _formatDate(payment['paymentDate']);
          int? serviceId = payment['serviceId'];
          int? inspectionId = payment['inspectionId'];
          int? bookingId = payment['bookingId'];

          String serviceName =
              serviceId != null
                  ? (serviceCategoryMap[serviceId] ?? "Loading...")
                  : "N/A";
          String remarks =
              (payment['remarks'] != null &&
                      payment['remarks'].toString().toLowerCase() != 'null')
                  ? payment['remarks']
                  : "N/A";

          String paymentRemarks =
              (serviceId != null)
                  ? "Extra Service Payment"
                  : (inspectionId != null && bookingId != null)
                  ? "Room Rent Payment"
                  : "Check-in Advance Payment";

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
                    _sectionTitle("Payment Information"),
                    _rowWithIcon(
                      Icons.attach_money,
                      "Amount",
                      "\$${payment['amount'].toString()}",
                    ),
                    _rowWithIcon(
                      Icons.calendar_today,
                      "Payment Date",
                      formattedDate,
                    ),
                    _rowWithIcon(Icons.category, "Service Name", serviceName),
                    _rowWithIcon(Icons.comment, "Remarks", remarks),
                    _rowWithIcon(
                      Icons.info_outline,
                      "Payment Remarks",
                      paymentRemarks,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _rowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text("$label: $value"),
        ],
      ),
    );
  }
}
