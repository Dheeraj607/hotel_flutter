import 'package:flutter/material.dart';
import 'package:hotel_management/screens/CheckoutReportScreen.dart';
import 'package:hotel_management/screens/all_customers.dart';
import 'package:hotel_management/screens/maintenance_staff_allotment.dart';
import 'package:hotel_management/screens/taxes_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            // child: Text(
            //   'Settings Content (Add any details you want here)',
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Directly start with ListView, no DrawerHeader
                Expanded(
                  child: ListView(
                    children: [
                      _buildDrawerItem(
                        context,
                        "Maintenance Staff",
                        Icons.engineering,
                        const MaintenanceStaffAllotmentPage(),
                      ),
                      _buildDrawerItem(
                        context,
                        "Taxes",
                        Icons.request_quote_outlined,
                        const TaxesPage(),
                      ),
                      _buildDrawerItem(
                        context,
                        "Checkout Report",
                        Icons.receipt_long_outlined,
                        const CheckoutReportScreen(),
                      ),
                      _buildDrawerItem(
                        context,
                        "All Customers",
                        Icons.person_2_outlined,
                        const AllCustomerScreen(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create individual settings items
  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget targetScreen,
  ) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: Icon(icon, color: Colors.deepOrangeAccent),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
