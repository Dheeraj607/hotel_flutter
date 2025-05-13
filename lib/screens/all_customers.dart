import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For formatting date
import 'package:transparent_image/transparent_image.dart';

class AllCustomerScreen extends StatefulWidget {
  const AllCustomerScreen({super.key});

  @override
  State<AllCustomerScreen> createState() => _AllCustomerScreenState();
}

class _AllCustomerScreenState extends State<AllCustomerScreen> {
  List<dynamic> customers = [];
  bool isLoading = true;

  DateTime? selectedCheckin;
  DateTime? selectedCheckout;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
    });

    try {
      String url = '$kBaseurl/api/customers/';
      List<String> params = [];

      if (selectedCheckin != null) {
        params.add(
          'checkin=${DateFormat('yyyy-MM-dd').format(selectedCheckin!)}',
        );
      }
      if (selectedCheckout != null) {
        params.add(
          'checkout=${DateFormat('yyyy-MM-dd').format(selectedCheckout!)}',
        );
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          customers = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('An error occurred: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> selectDate({required bool isCheckin}) async {
    DateTime initialDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isCheckin) {
          selectedCheckin = picked;
        } else {
          selectedCheckout = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers'),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Column(
        children: [
          // Date filter bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => selectDate(isCheckin: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedCheckin != null
                            ? 'Check-in: ${DateFormat('yyyy-MM-dd').format(selectedCheckin!)}'
                            : 'Select Check-in',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => selectDate(isCheckin: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedCheckout != null
                            ? 'Checkout: ${DateFormat('yyyy-MM-dd').format(selectedCheckout!)}'
                            : 'Select Checkout',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: fetchCustomers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Filter'),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : customers.isEmpty
                    ? const Center(child: Text('No customers available'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final imageProof =
                            customer['ImageProof'] as List<dynamic>;

                        final allPhotos = <String>[];
                        for (var proof in imageProof) {
                          final photos = proof['photos'] as List<dynamic>;
                          allPhotos.addAll(
                            photos.map((p) => '$kBaseurl/media/$p'),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        Colors.deepOrangeAccent.shade100,
                                    child: Text(
                                      customer['fullName'][0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer['fullName'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Email: ${customer['emailAddress'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Contact: ${customer['contactNumber']}'),
                              Text(
                                'Passport ID: ${customer['idPassportNumber']}',
                              ),
                              const SizedBox(height: 12),
                              if (allPhotos.isNotEmpty)
                                SizedBox(
                                  height: 80,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: allPhotos.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, photoIndex) {
                                      final photoUrl = allPhotos[photoIndex];

                                      return GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (_) => Dialog(
                                                  backgroundColor: Colors.black,
                                                  insetPadding: EdgeInsets.all(
                                                    10,
                                                  ),
                                                  child: InteractiveViewer(
                                                    panEnabled: true,
                                                    minScale: 0.5,
                                                    maxScale: 4,
                                                    child: FadeInImage.memoryNetwork(
                                                      placeholder:
                                                          kTransparentImage,
                                                      image: photoUrl,
                                                      fit: BoxFit.contain,
                                                      imageErrorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Container(
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade300,
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: AnimatedOpacity(
                                            opacity: 1.0,
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),
                                            child: FadeInImage.memoryNetwork(
                                              placeholder: kTransparentImage,
                                              image: photoUrl,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              imageErrorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade300,
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Text('No images available'),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:hotel_management/constant.dart';
// import 'package:http/http.dart' as http;
// import 'package:transparent_image/transparent_image.dart';

// class AllCustomerScreen extends StatefulWidget {
//   const AllCustomerScreen({super.key});

//   @override
//   State<AllCustomerScreen> createState() => _AllCustomerScreenState();
// }

// class _AllCustomerScreenState extends State<AllCustomerScreen> {
//   List<dynamic> customers = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchCustomers();
//   }

//   Future<void> fetchCustomers() async {
//     try {
//       final response = await http.get(Uri.parse('$kBaseurl/api/customers/'));
//       if (response.statusCode == 200) {
//         setState(() {
//           customers = jsonDecode(response.body);
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load customers');
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       showDialog(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               title: const Text('Error'),
//               content: Text('An error occurred: $e'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('OK'),
//                 ),
//               ],
//             ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('All Customers'),
//         backgroundColor: Colors.deepOrangeAccent,
//       ),
//       body:
//           isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : customers.isEmpty
//               ? const Center(child: Text('No customers available'))
//               : ListView.builder(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: customers.length,
//                 itemBuilder: (context, index) {
//                   final customer = customers[index];
//                   final imageProof = customer['ImageProof'] as List<dynamic>;

//                   // Collect all photos in one list
//                   final allPhotos = <String>[];
//                   for (var proof in imageProof) {
//                     final photos = proof['photos'] as List<dynamic>;
//                     allPhotos.addAll(photos.map((p) => '$kBaseurl/media/$p'));
//                   }

//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 16),
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             CircleAvatar(
//                               radius: 30,
//                               backgroundColor: Colors.deepOrangeAccent.shade100,
//                               child: Text(
//                                 customer['fullName'][0].toUpperCase(),
//                                 style: const TextStyle(
//                                   fontSize: 24,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     customer['fullName'],
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                     maxLines: 1,
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     'Email: ${customer['emailAddress'] ?? 'N/A'}',
//                                     style: TextStyle(
//                                       color: Colors.grey.shade600,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Text('Contact: ${customer['contactNumber']}'),
//                         Text('Passport ID: ${customer['idPassportNumber']}'),

//                         const SizedBox(height: 12),

//                         // Horizontal scroll gallery
//                         if (allPhotos.isNotEmpty)
//                           SizedBox(
//                             height: 80,
//                             child: ListView.separated(
//                               scrollDirection: Axis.horizontal,
//                               itemCount: allPhotos.length,
//                               separatorBuilder:
//                                   (_, __) => const SizedBox(width: 8),
//                               itemBuilder: (context, photoIndex) {
//                                 final photoUrl = allPhotos[photoIndex];
//                                 return ClipRRect(
//                                   borderRadius: BorderRadius.circular(12),
//                                   child: AnimatedOpacity(
//                                     opacity:
//                                         1.0, // Fully visible after image is loaded
//                                     duration: const Duration(
//                                       milliseconds: 800,
//                                     ), // Adjust fade duration here
//                                     child: FadeInImage.memoryNetwork(
//                                       placeholder: kTransparentImage,
//                                       image: photoUrl,
//                                       width: 80,
//                                       height: 80,
//                                       fit: BoxFit.cover,
//                                       imageErrorBuilder:
//                                           (context, error, stackTrace) =>
//                                               Container(
//                                                 width: 80,
//                                                 height: 80,
//                                                 color: Colors.grey.shade300,
//                                                 child: Icon(
//                                                   Icons.broken_image,
//                                                   color: Colors.grey.shade600,
//                                                 ),
//                                               ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           )
//                         else
//                           const Text('No images available'),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//     );
//   }
// }
