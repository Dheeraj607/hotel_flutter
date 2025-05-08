import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final TextEditingController checkInTimeController = TextEditingController();
  final TextEditingController advanceController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController paymentTypeController = TextEditingController();
  final TextEditingController proofNameController = TextEditingController();
  final TextEditingController optionalNameController = TextEditingController();

  String? selectedPaymentMethod;
  String? selectedPaymentStatus;
  List<XFile> selectedImages = [];
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

  Future<void> _selectCheckInTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        checkInTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? photo = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                    );
                    if (photo != null) {
                      setState(() {
                        selectedImages.add(photo);
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        selectedImages.add(image);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildImagePreview() {
    return GridView.count(
      shrinkWrap: true, // Important to prevent unbounded height in Column
      crossAxisCount: 2, // 2 columns
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      physics:
          NeverScrollableScrollPhysics(), // So it doesn't scroll inside the form
      children:
          selectedImages.map((image) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image.path),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          selectedImages.remove(image);
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Future<void> bookRoom() async {
    if (!_formKey.currentState!.validate()) {
      _showDialog("Error", "Please fill in all required fields.");
      return;
    }

    // Validate checkInTime format
    if (checkInTimeController.text.isEmpty) {
      _showDialog("Error", "Check-In Time is required");
      return;
    }
    try {
      DateFormat('hh:mm a').parse(checkInTimeController.text.trim());
    } catch (e) {
      _showDialog("Error", "Invalid Check-In Time format. Use HH:MM AM/PM");
      return;
    }

    // Show loading indicator
    setState(() => isLoading = true);

    // Debug print
    print('--- Form Data ---');
    print('Full Name: ${fullNameController.text.trim()}');
    print('Passport ID: ${passportController.text.trim()}');
    print('Contact Number: ${contactController.text.trim()}');
    print('Email: ${emailController.text.trim()}');
    print('Nationality: ${nationalityController.text.trim()}');
    print('Special Requests: ${specialRequestsController.text.trim()}');
    print('Room ID: ${roomIdController.text.trim()}');
    print('Check-In Date: ${checkInDateController.text.trim()}');
    print('Check-In Time: ${checkInTimeController.text.trim()}');
    print('Advance Payment: ${advanceController.text.trim()}');
    print('Total Rent: ${rentController.text.trim()}');
    print('Amount: ${amountController.text.trim()}');
    print('Transaction ID: ${transactionIdController.text.trim()}');
    print('Payment Type: ${paymentTypeController.text.trim()}');
    print('Optional Name: ${optionalNameController.text.trim()}');
    print('Selected Payment Method: $selectedPaymentMethod');
    print('Selected Payment Status: $selectedPaymentStatus');

    for (var img in selectedImages) {
      print('Selected Image: ${img.path}');
    }

    final url = Uri.parse("$kBaseurl/api/book-room/");

    // Prepare MultipartRequest
    final request = http.MultipartRequest("POST", url);

    // 🟢 1) Add normal fields
    request.fields['roomId'] = roomIdController.text.trim();

    // Customer input JSON field
    request.fields['customer_input'] = jsonEncode({
      "fullName": fullNameController.text.trim(),
      "idPassportNumber": passportController.text.trim(),
      "contactNumber": contactController.text.trim(),
      "emailAddress": emailController.text.trim(),
      "nationality": nationalityController.text.trim(),
      "specialRequests": specialRequestsController.text.trim(),
      // "proofName": proofNameController.text.trim(),
    });

    // Other fields
    request.fields['checkInDate'] = DateFormat(
      "yyyy-MM-dd",
    ).format(selectedCheckInDate ?? DateTime.now());
    request.fields['checkInTime'] = checkInTimeController.text.trim();
    request.fields['Advance'] =
        (double.tryParse(advanceController.text) ?? 0.0).toString();
    request.fields['Rent'] =
        (double.tryParse(rentController.text) ?? 0.0).toString();

    // Payment JSON field
    request.fields['payment'] = jsonEncode({
      "amount": double.tryParse(amountController.text) ?? 0.0,
      "paymentMethod": selectedPaymentMethod,
      "transactionId": transactionIdController.text.trim(),
      "paymentStatus": selectedPaymentStatus,
      "paymentType": paymentTypeController.text.trim(),
    });

    // 🟢 2) Add images
    for (var img in selectedImages) {
      request.files.add(await http.MultipartFile.fromPath('photos', img.path));
    }
    print("request:${request.fields}");
    try {
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');
      if (response.statusCode == 201) {
        print("Success");
        clearFields();
        Navigator.pop(context);
      } else {
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);
        print('Error Response: $responseData');

        if (responseData['customer_input'] != null &&
            responseData['customer_input'].containsKey('emailAddress')) {
          final errorMessage =
              responseData['customer_input']['emailAddress']?.join(", ") ??
              "Unknown error";
          _showDialog("Error", errorMessage);
        } else {
          _showDialog("Error", "Booking failed");
        }
      }
    } catch (error) {
      print('Error: $error');
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
    checkInTimeController.clear();
    advanceController.clear();
    rentController.clear();
    amountController.clear();
    transactionIdController.clear();
    paymentTypeController.clear();
    optionalNameController.clear();
    selectedPaymentMethod = null;
    selectedPaymentStatus = null;
    selectedCheckInDate = null;
    selectedImages.clear();
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
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCard(fullNameController, "Full Name", Icon(Icons.person)),
                _buildCard(
                  passportController,
                  "Passport ID",
                  Icon(Icons.file_copy),
                ),
                _buildCard(
                  contactController,
                  "Contact Number",
                  Icon(Icons.phone),
                ),
                _buildCard(emailController, "Email", Icon(Icons.email)),
                _buildCard(
                  nationalityController,
                  "Nationality",
                  Icon(Icons.location_city),
                ),
                _buildCard(
                  specialRequestsController,
                  "Special Requests",
                  Icon(Icons.request_page),
                ),
                _buildCard(
                  roomIdController,
                  "Room ID",
                  Icon(Icons.room),
                  isNumber: true,
                ),
                GestureDetector(
                  onTap: () => _selectCheckInDate(context),
                  child: AbsorbPointer(
                    child: _buildCard(
                      checkInDateController,
                      "Check-In Date",
                      Icon(Icons.calendar_month),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectCheckInTime(context),
                  child: AbsorbPointer(
                    child: _buildCard(
                      checkInTimeController,
                      "Check-In Time",
                      Icon(Icons.timelapse),
                    ),
                  ),
                ),
                _buildCard(
                  advanceController,
                  "Advance Payment",
                  Icon(Icons.currency_rupee),
                  isNumber: true,
                ),
                _buildCard(
                  rentController,
                  "Total Rent",
                  Icon(Icons.currency_rupee),
                  isNumber: true,
                ),
                _buildCard(
                  amountController,
                  "Payment Amount",
                  Icon(Icons.currency_rupee),
                  isNumber: true,
                ),
                _buildDropdown(
                  "Payment Method",
                  paymentMethods,
                  selectedPaymentMethod,
                  (String? value) =>
                      setState(() => selectedPaymentMethod = value),
                ),
                _buildCard(
                  transactionIdController,
                  "Transaction ID",
                  Icon(Icons.currency_rupee),
                ),
                _buildDropdown(
                  "Payment Status",
                  paymentStatuses,
                  selectedPaymentStatus,
                  (String? value) =>
                      setState(() => selectedPaymentStatus = value),
                ),
                _buildCard(
                  paymentTypeController,
                  "Payment Type",
                  Icon(Icons.payment),
                ),

                // Image Picker Button and Preview
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upload ID / Proof",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(),
                              icon: const Icon(
                                Icons.browser_updated,
                                color: Colors.white,
                              ),
                              label: const Text("Browse"),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildImagePreview(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                      onTap: bookRoom,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlueAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.4),
                              offset: Offset(0, 8),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Book Room",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to build the cards (for form fields)
  Widget _buildCard(
    TextEditingController controller,
    String label,
    Icon ic, {
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
            prefixIcon: ic,
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

  // Dropdown builder
  Widget _buildDropdown(
    String label,
    List<String> options,
    String? selectedOption,
    ValueChanged<String?> onChanged,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: DropdownButtonFormField<String>(
          value: selectedOption,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          items:
              options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:hotel_management/constant.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'room_detail_screen.dart';
// import 'dart:io';

// class BookRoomScreen extends StatefulWidget {
//   final DateTime checkInDate;
//   final Map<String, dynamic> roomData;

//   const BookRoomScreen({
//     super.key,
//     required this.checkInDate,
//     required this.roomData,
//   });

//   @override
//   _BookRoomScreenState createState() => _BookRoomScreenState();
// }

// class _BookRoomScreenState extends State<BookRoomScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController passportController = TextEditingController();
//   final TextEditingController contactController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController nationalityController = TextEditingController();
//   final TextEditingController specialRequestsController =
//       TextEditingController();
//   final TextEditingController roomIdController = TextEditingController();
//   final TextEditingController checkInDateController = TextEditingController();
//   final TextEditingController checkInTimeController = TextEditingController();
//   final TextEditingController advanceController = TextEditingController();
//   final TextEditingController rentController = TextEditingController();
//   final TextEditingController amountController = TextEditingController();
//   final TextEditingController transactionIdController = TextEditingController();
//   final TextEditingController paymentTypeController = TextEditingController();

//   String? selectedPaymentMethod;
//   String? selectedPaymentStatus;
//   bool isLoading = false;
//   DateTime? selectedCheckInDate;

//   final List<String> paymentMethods = ["Credit Card", "Cash", "UPI", "Online"];
//   final List<String> paymentStatuses = ["Pending", "Paid"];

//   @override
//   void initState() {
//     super.initState();
//     selectedCheckInDate = widget.checkInDate;
//     checkInDateController.text = DateFormat(
//       "yyyy-MM-dd",
//     ).format(widget.checkInDate);

//     // Autofill room details
//     roomIdController.text = widget.roomData['id'].toString();
//     advanceController.text = widget.roomData['Advance'].toString();
//     rentController.text = widget.roomData['Rent'].toString();
//   }

//   Future<void> _selectCheckInDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedCheckInDate ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         selectedCheckInDate = picked;
//         checkInDateController.text = DateFormat("yyyy-MM-dd").format(picked);
//       });
//     }
//   }

//   Future<void> _selectCheckInTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );

//     if (picked != null) {
//       setState(() {
//         checkInTimeController.text = picked.format(context);
//       });
//     }
//   }

//   Future<void> bookRoom() async {
//     if (!_formKey.currentState!.validate()) return;

//     // Validate checkInTime format
//     if (checkInTimeController.text.isEmpty) {
//       _showDialog("Error", "Check-In Time is required");
//       return;
//     }
//     try {
//       DateFormat('hh:mm a').parse(checkInTimeController.text.trim());
//     } catch (e) {
//       _showDialog("Error", "Invalid Check-In Time format. Use HH:MM AM/PM");
//       return;
//     }

//     setState(() => isLoading = true);

//     // Print all form field values for debugging
//     print('--- Form Data ---');
//     print('Full Name: ${fullNameController.text.trim()}');
//     print('Passport ID: ${passportController.text.trim()}');
//     print('Contact Number: ${contactController.text.trim()}');
//     print('Email: ${emailController.text.trim()}');
//     print('Nationality: ${nationalityController.text.trim()}');
//     print('Special Requests: ${specialRequestsController.text.trim()}');
//     print('Room ID: ${roomIdController.text.trim()}');
//     print('Check-In Date: ${checkInDateController.text.trim()}');
//     print('Check-In Time: ${checkInTimeController.text.trim()}');
//     print('Advance Payment: ${advanceController.text.trim()}');
//     print('Total Rent: ${rentController.text.trim()}');
//     print('Payment Amount: ${amountController.text.trim()}');
//     print('Payment Method: $selectedPaymentMethod');
//     print('Transaction ID: ${transactionIdController.text.trim()}');
//     print('Payment Status: $selectedPaymentStatus');
//     print('Payment Type: ${paymentTypeController.text.trim()}');
//     print('-----------------');

//     final url = Uri.parse("$kBaseurl/api/book-room/");

//     // Prepare the request body
//     final Map<String, dynamic> requestBody = {
//       "customer_input": {
//         "fullName": fullNameController.text.trim(),
//         "idPassportNumber": passportController.text.trim(),
//         "contactNumber": contactController.text.trim(),
//         "emailAddress": emailController.text.trim(),
//         "nationality": nationalityController.text.trim(),
//         "specialRequests": specialRequestsController.text.trim(),
//       },
//       "roomId": int.tryParse(roomIdController.text) ?? 0,
//       "checkInDate": DateFormat(
//         "yyyy-MM-dd",
//       ).format(selectedCheckInDate ?? DateTime.now()),
//       "checkInTime": checkInTimeController.text.trim(),
//       "Advance": double.tryParse(advanceController.text) ?? 0.0,
//       "Rent": double.tryParse(rentController.text) ?? 0.0,
//       "payment": {
//         "amount": double.tryParse(amountController.text) ?? 0.0,
//         "paymentMethod": selectedPaymentMethod,
//         "transactionId": transactionIdController.text.trim(),
//         "paymentStatus": selectedPaymentStatus,
//         "paymentType": paymentTypeController.text.trim(),
//       },
//     };

//     // Print request body for debugging
//     print("Request Body: ${jsonEncode(requestBody)}");

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(requestBody),
//       );

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');
//       final responseData = jsonDecode(response.body);
//       if (response.statusCode == 201) {
//         _showDialog("Success", "Room booked successfully!");
//         clearFields();
//         Navigator.pop(context);
//       } else if (responseData['customer_input'] != null &&
//           responseData['customer_input'].containsKey('emailAddress')) {
//         final errorMessage =
//             responseData['customer_input']['emailAddress']?.join(", ") ??
//             "Unknown error";
//         _showDialog("Error", errorMessage);
//       } else if (responseData['customer_input'] != null &&
//           responseData['customer_input'].containsKey('contactNumber')) {
//         final errorMessage =
//             responseData['customer_input']['contactNumber']?.join(", ") ??
//             "Unknown error";
//         _showDialog("Error", errorMessage);
//       } else if (responseData['customer_input'] != null &&
//           responseData['customer_input'].containsKey('idPassportNumber')) {
//         final errorMessage =
//             responseData['customer_input']['idPassportNumber']?.join(", ") ??
//             "Unknown error";
//         _showDialog("Error", errorMessage);
//       } else if (responseData['customer_input'] != null &&
//           responseData['customer_input'].containsKey('transactionId')) {
//         final errorMessage =
//             responseData['customer_input']['transactionId']?.join(", ") ??
//             "Unknown error";
//         _showDialog("Error", errorMessage);
//       } else {
//         _showDialog("Error", "Network Error");
//       }
//     } catch (error) {
//       print('Error: $error');
//       _showDialog("Network Error", "Could not connect to the server.");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void clearFields() {
//     fullNameController.clear();
//     passportController.clear();
//     contactController.clear();
//     emailController.clear();
//     nationalityController.clear();
//     specialRequestsController.clear();
//     roomIdController.clear();
//     checkInDateController.clear();
//     checkInTimeController.clear();
//     advanceController.clear();
//     rentController.clear();
//     amountController.clear();
//     transactionIdController.clear();
//     paymentTypeController.clear();
//     selectedPaymentMethod = null;
//     selectedPaymentStatus = null;
//     selectedCheckInDate = null;
//     setState(() {});
//   }

//   void _showDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text(title),
//             content: Text(message),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("OK"),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Book a Room"),
//         backgroundColor: const Color.fromARGB(255, 245, 129, 86),
//         // flexibleSpace: Container(
//         //   decoration: const BoxDecoration(
//         //     gradient: LinearGradient(
//         //       colors: [Colors.blue, Colors.purple],
//         //       begin: Alignment.topLeft,
//         //       end: Alignment.bottomRight,
//         //     ),
//         //   ),
//         // ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 _buildCard(fullNameController, "Full Name"),
//                 _buildCard(passportController, "Passport ID"),
//                 _buildCard(contactController, "Contact Number"),
//                 _buildCard(emailController, "Email"),
//                 _buildCard(nationalityController, "Nationality"),
//                 _buildCard(specialRequestsController, "Special Requests"),
//                 _buildCard(roomIdController, "Room ID", isNumber: true),
//                 GestureDetector(
//                   onTap: () => _selectCheckInDate(context),
//                   child: AbsorbPointer(
//                     child: _buildCard(checkInDateController, "Check-In Date"),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () => _selectCheckInTime(context),
//                   child: AbsorbPointer(
//                     child: _buildCard(checkInTimeController, "Check-In Time"),
//                   ),
//                 ),
//                 _buildCard(
//                   advanceController,
//                   "Advance Payment",
//                   isNumber: true,
//                 ),
//                 _buildCard(rentController, "Total Rent", isNumber: true),
//                 _buildCard(amountController, "Payment Amount", isNumber: true),
//                 _buildDropdown(
//                   "Payment Method",
//                   paymentMethods,
//                   selectedPaymentMethod,
//                   (String? value) =>
//                       setState(() => selectedPaymentMethod = value),
//                 ),
//                 _buildCard(transactionIdController, "Transaction ID"),
//                 _buildDropdown(
//                   "Payment Status",
//                   paymentStatuses,
//                   selectedPaymentStatus,
//                   (String? value) =>
//                       setState(() => selectedPaymentStatus = value),
//                 ),
//                 _buildCard(paymentTypeController, "Payment Type"),
//                 const SizedBox(height: 20),
//                 isLoading
//                     ? const CircularProgressIndicator()
//                     : ElevatedButton(
//                       onPressed: bookRoom,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         backgroundColor: Colors.blueAccent,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),

//                       child: const Text(
//                         "Book Room",
//                         style: TextStyle(fontSize: 18, color: Colors.white),
//                       ),
//                     ),
//                 // const SizedBox(height: 10),
//                 // TextButton(
//                 //   onPressed: () {
//                 //     Navigator.push(
//                 //       context,
//                 //       MaterialPageRoute(
//                 //         builder: (context) => RoomDetailsScreen(),
//                 //       ),
//                 //     );
//                 //   },
//                 //   child: const Text(
//                 //     "View Room List",
//                 //     style: TextStyle(color: Colors.blue, fontSize: 16),
//                 //   ),
//                 // ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(
//     TextEditingController controller,
//     String label, {
//     bool isNumber = false,
//   }) {
//     return Card(
//       elevation: 3,
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         child: TextFormField(
//           controller: controller,
//           decoration: InputDecoration(
//             border: InputBorder.none,
//             labelText: label,
//           ),
//           keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return "$label is required";
//             }
//             return null;
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown(
//     String label,
//     List<String> items,
//     String? selectedValue,
//     ValueChanged<String?> onChanged,
//   ) {
//     return Card(
//       elevation: 3,
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
//         child: DropdownButtonFormField<String>(
//           decoration: InputDecoration(
//             border: InputBorder.none,
//             labelText: label,
//           ),
//           value: selectedValue,
//           items:
//               items
//                   .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                   .toList(),
//           onChanged: onChanged,
//           validator: (value) => value == null ? "Please select $label" : null,
//         ),
//       ),
//     );
//   }
// }
