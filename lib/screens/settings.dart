import 'package:flutter/material.dart';
import 'package:hotel_management/screens/CheckoutReportScreen.dart';
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
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
        elevation: 0,
        // backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildSettingsCard(
                    context,
                    "Maintenance Staff",
                    Icons.engineering,
                    const MaintenanceStaffAllotmentPage(),
                    Colors.deepPurpleAccent,
                  ),
                  _buildSettingsCard(
                    context,
                    "Taxes",
                    Icons.request_quote_outlined,
                    const TaxesPage(),
                    Colors.teal,
                  ),
                  _buildSettingsCard(
                    context,
                    "Checkout Report",
                    Icons.receipt_long_outlined,
                    const CheckoutReportScreen(),
                    Colors.orange,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget targetScreen,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: color.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, size: 30, color: color),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
