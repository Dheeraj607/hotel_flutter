import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

class AllCustomerScreen extends StatefulWidget {
  const AllCustomerScreen({super.key});

  @override
  State<AllCustomerScreen> createState() => _AllCustomerScreenState();
}

class _AllCustomerScreenState extends State<AllCustomerScreen> {
  List<dynamic> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      final response = await http.get(Uri.parse('$kBaseurl/api/customers/'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers'),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : customers.isEmpty
              ? const Center(child: Text('No customers available'))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final imageProof = customer['ImageProof'] as List<dynamic>;

                  // Collect all photos in one list
                  final allPhotos = <String>[];
                  for (var proof in imageProof) {
                    final photos = proof['photos'] as List<dynamic>;
                    allPhotos.addAll(photos.map((p) => '$kBaseurl/media/$p'));
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
                              backgroundColor: Colors.deepOrangeAccent.shade100,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text('Passport ID: ${customer['idPassportNumber']}'),

                        const SizedBox(height: 12),

                        // Horizontal scroll gallery
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
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedOpacity(
                                    opacity:
                                        1.0, // Fully visible after image is loaded
                                    duration: const Duration(
                                      milliseconds: 800,
                                    ), // Adjust fade duration here
                                    child: FadeInImage.memoryNetwork(
                                      placeholder: kTransparentImage,
                                      image: photoUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      imageErrorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey.shade300,
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey.shade600,
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
    );
  }
}
