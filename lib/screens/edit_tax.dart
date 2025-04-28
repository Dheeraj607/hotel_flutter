import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constant.dart';

class EditTaxPage extends StatefulWidget {
  final Map<String, dynamic> tax;

  const EditTaxPage({super.key, required this.tax});

  @override
  State<EditTaxPage> createState() => _EditTaxPageState();
}

class _EditTaxPageState extends State<EditTaxPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController stateGSTController = TextEditingController();
  final TextEditingController centralGSTController = TextEditingController();

  int? selectedCategory;
  List<dynamic> categories = [];

  bool isRent = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    stateGSTController.text = widget.tax['stateGST']?.toString() ?? '';
    centralGSTController.text = widget.tax['centralGST']?.toString() ?? '';
    selectedCategory = widget.tax['category'];
    isRent = widget.tax['type'] == 'Rent';
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final url = Uri.parse('$kBaseurl/api/extra-service-categories/');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        categories = json.decode(response.body);
      });
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final url = Uri.parse('$kBaseurl/api/taxes/update/${widget.tax['taxId']}/');
    final body = json.encode({
      "type": widget.tax['type'],
      "category": isRent ? null : selectedCategory,
      "stateGST": stateGSTController.text,
      "centralGST": centralGSTController.text,
    });

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    setState(() => isSubmitting = false);

    if (response.statusCode == 200 || response.statusCode == 204) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update tax')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Tax')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    'Edit Tax Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  if (!isRent)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedCategory,
                          items:
                              categories.map<DropdownMenuItem<int>>((cat) {
                                return DropdownMenuItem<int>(
                                  value: cat['categoryId'],
                                  child: Text(cat['categoryName']),
                                );
                              }).toList(),
                          onChanged:
                              (value) =>
                                  setState(() => selectedCategory = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select Category',
                          ),
                          validator:
                              (value) => value == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  const Text('State GST (%)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: stateGSTController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter State GST',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Central GST (%)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: centralGSTController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter Central GST',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isSubmitting
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                              : const Text(
                                'Update Tax',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
