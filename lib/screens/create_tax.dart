import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hotel_management/constant.dart';

class CreateTaxPage extends StatefulWidget {
  const CreateTaxPage({super.key});

  @override
  State<CreateTaxPage> createState() => _CreateTaxPageState();
}

class _CreateTaxPageState extends State<CreateTaxPage> {
  final _formKey = GlobalKey<FormState>();
  String? type;
  double? stateGST;
  double? centralGST;
  int? selectedCategory;
  List<dynamic> categories = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$kBaseurl/api/extra-service-categories/'),
    );
    if (response.statusCode == 200) {
      setState(() => categories = json.decode(response.body));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load categories')),
      );
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (type == 'Extra Service' && selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    final body = json.encode({
      "type": type,
      "category": type == 'Extra Service' ? selectedCategory : null,
      "stateGST": stateGST,
      "centralGST": centralGST,
    });

    final response = await http.post(
      Uri.parse('$kBaseurl/api/taxes/'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    setState(() => isLoading = false);

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tax created successfully!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create tax: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Tax')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                          DropdownMenuItem(
                            value: 'Extra Service',
                            child: Text('Extra Service'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Select Type',
                          border: OutlineInputBorder(),
                        ),
                        onChanged:
                            (val) => setState(() {
                              type = val;
                              selectedCategory = null;
                            }),
                        validator:
                            (val) =>
                                val == null ? 'Please select a type' : null,
                      ),
                      const SizedBox(height: 16),

                      if (type == 'Extra Service')
                        DropdownButtonFormField<int>(
                          value: selectedCategory,
                          items:
                              categories.map<DropdownMenuItem<int>>((cat) {
                                return DropdownMenuItem<int>(
                                  value: cat['categoryId'],
                                  child: Text(cat['categoryName']),
                                );
                              }).toList(),
                          decoration: const InputDecoration(
                            labelText: 'Select Category',
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (val) => setState(() => selectedCategory = val),
                        ),

                      if (type == 'Extra Service') const SizedBox(height: 16),

                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'State GST (%)',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Enter valid number'
                                    : null,
                        onSaved:
                            (val) => stateGST = double.tryParse(val ?? '0'),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Central GST (%)',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Enter valid number'
                                    : null,
                        onSaved:
                            (val) => centralGST = double.tryParse(val ?? '0'),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitForm,
                          child: const Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
