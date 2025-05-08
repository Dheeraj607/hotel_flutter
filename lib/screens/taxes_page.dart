import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hotel_management/constant.dart';
import 'package:hotel_management/screens/create_tax.dart';
import 'package:hotel_management/screens/edit_tax.dart';
import 'package:http/http.dart' as http;

class TaxesPage extends StatefulWidget {
  const TaxesPage({super.key});

  @override
  State<TaxesPage> createState() => _TaxesPageState();
}

class _TaxesPageState extends State<TaxesPage> {
  List<dynamic> taxes = [];
  Map<int, String> categoryMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final taxUrl = Uri.parse('$kBaseurl/api/taxes/');
    final categoryUrl = Uri.parse('$kBaseurl/api/extra-service-categories/');

    try {
      final taxResponse = await http.get(taxUrl);
      final categoryResponse = await http.get(categoryUrl);

      if (taxResponse.statusCode == 200 && categoryResponse.statusCode == 200) {
        final taxData = json.decode(taxResponse.body);
        final categoryData = json.decode(categoryResponse.body);

        Map<int, String> categoryLookup = {};
        for (var item in categoryData) {
          categoryLookup[item['categoryId']] = item['categoryName'];
        }

        setState(() {
          taxes = taxData;
          categoryMap = categoryLookup;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  void onCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTaxPage()),
    );

    if (result == true) {
      fetchData(); // Refresh the tax list after creating a new tax
    }
  }

  void onEdit(Map<String, dynamic> tax) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTaxPage(tax: tax)),
    );

    if (result == true) {
      fetchData(); // Refresh data after editing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxes'),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreate,
        icon: const Icon(Icons.add),
        label: const Text('Create Tax'),
        backgroundColor: Colors.blue,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.builder(
                  itemCount: taxes.length,
                  itemBuilder: (context, index) {
                    final tax = taxes[index];
                    final categoryId = tax['category'];
                    final categoryName =
                        categoryId != null
                            ? categoryMap[categoryId] ?? 'Unknown'
                            : 'N/A';

                    bool isRent = tax['type'] == 'Rent';
                    bool isExtraService = tax['type'] == 'Extra Service';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Rent or Extra Service Icon
                                      Icon(
                                        isRent
                                            ? Icons.home
                                            : Icons.local_dining,
                                        color:
                                            isRent
                                                ? Colors.green
                                                : Colors.orange,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      // Type Title (Rent or Extra Service)
                                      Text(
                                        tax['type'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Display Category for non-Rent Types
                                  if (!isRent)
                                    Text(
                                      categoryName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  // GST Information (State and Central)
                                  Row(
                                    children: [
                                      _buildGSTBox(
                                        'State GST',
                                        tax['stateGST'],
                                      ),
                                      const SizedBox(width: 16),
                                      _buildGSTBox(
                                        'Central GST',
                                        tax['centralGST'],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => onEdit(tax),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildGSTBox(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            '${value ?? 0}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
