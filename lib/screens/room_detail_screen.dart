import 'dart:convert';
import 'dart:ui';
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
      appBar: AppBar(
        title: Text('Room Details'),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
      ),
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

    // String imageUrl = room['imageUrl']?.toString() ?? 'images/room.jpg';
    // bool isNetwork = imageUrl.startsWith('http');

    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade200,
                const Color.fromARGB(255, 240, 244, 243),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  'images/room.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Room Details
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Room No: ${room['roomNumber'] ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                    SizedBox(height: 10),
                    Text(
                      "Room Type: ${room['roomType'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    if (isOccupied)
                      CustomerDetails(
                        bookings: bookings,
                        onDataChanged: onDataChanged,
                      ),
                    SizedBox(height: 12),
                    if (isOccupied)
                      ElevatedButton.icon(
                        onPressed: () async {
                          print(
                            'checkinTime passed to ExtraServicesScreen: ${bookings[0]['checkInTime'].toString()}',
                          );
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
                                    checkinDate:
                                        bookings[0]['checkInDate'].toString(),
                                    checkinTime:
                                        bookings[0]['checkInTime'].toString(),
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
                          foregroundColor: const Color.fromARGB(
                            255,
                            39,
                            55,
                            112,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
                  foregroundColor: const Color.fromARGB(255, 39, 55, 112),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                  foregroundColor: const Color.fromARGB(255, 39, 55, 112),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
        return data['categoryName'] ?? 'No Category';
      } else if (response.statusCode == 404) {
        return 'Category not found';
      } else {
        return 'Error (${response.statusCode})';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == 'null') return "N/A";
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd • hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildPaymentTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getTagColor(String type) {
    switch (type) {
      case 'Extra Service Payment':
        return Colors.purple;
      case 'Room Rent Payment':
        return Colors.teal;
      case 'Check-in Advance Payment':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refreshData() async {
    await _loadCategoryNames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Payment Details"),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          itemCount: widget.paymentDetails.length,
          padding: const EdgeInsets.symmetric(vertical: 10),
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

            String paymentRemarks =
                (serviceId != null)
                    ? "Extra Service Payment"
                    : (inspectionId != null && bookingId != null)
                    ? "Room Rent Payment"
                    : "Check-in Advance Payment";

            Color chipColor = _getTagColor(paymentRemarks);

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Amount and Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "₹ ${payment['amount'].toString()}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              _buildPaymentTypeChip(paymentRemarks, chipColor),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 10),

                          // Payment Date
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Service Name
                          Row(
                            children: [
                              const Icon(
                                Icons.miscellaneous_services_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Service: $serviceName",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
