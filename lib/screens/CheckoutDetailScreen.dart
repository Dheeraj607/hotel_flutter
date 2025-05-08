import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CheckoutDetailScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const CheckoutDetailScreen({super.key, required this.report});

  Future<void> _downloadPdf(BuildContext context) async {
    final pdf = pw.Document();

    // Load Noto Sans font
    final font = await PdfGoogleFonts.notoSansRegular();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Checkout Report',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 16),
              _buildSectionTitle('Room Details'),
              _buildTable([
                ['Room No', report['roomNo']],
                ['Room Type', report['roomType']],
                ['Check-in Date', report['checkinDate']],
                ['Check-in Time', report['checkinTime']],
                ['Check-out Date', report['checkoutDate']],
                ['Check-out Time', report['checkoutTime']],
              ]),
              pw.SizedBox(height: 16),
              _buildSectionTitle('Financial Summary'),
              _buildTable([
                ['Total Days Stayed', report['totalDaysStayed']],

                ['Total Rent', report['totalRent']],

                ['Extra Services', report['extraserviceTotalAmount']],

                ['Additional Charges', report['additionalCharges']],

                ['Total Amount', report['totalAmount']],
                ['State GST', report['stateGST']],
                ['Central GST', report['centralGST']],
                ['Total with Tax', report['totalAmountIncludingTax']],

                ['Discount', report['discount']],
                ['Advance Paid', report['checkinAdvance']],
              ]),
              pw.SizedBox(height: 16),
              _buildSectionTitle('Other Information'),
              _buildTable([
                ['Remarks', report['remarks']],
              ]),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey,
        ),
      ),
    );
  }

  static pw.Widget _buildTable(List<List<dynamic>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(5),
      },
      children:
          rows.map((row) {
            return pw.TableRow(
              children:
                  row.map((cell) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        cell.toString(),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
            );
          }).toList(),
    );
  }

  // static pw.TableRow _buildRow(String title, dynamic value, pw.Font font) {
  //   String displayValue = _formatValue(title, value);

  //   return pw.TableRow(
  //     children: [
  //       pw.Container(
  //         padding: const pw.EdgeInsets.all(8),
  //         color: PdfColors.grey300,
  //         child: pw.Text(
  //           title,
  //           style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
  //         ),
  //       ),
  //       pw.Container(
  //         padding: const pw.EdgeInsets.all(8),
  //         child: pw.Text(displayValue, style: pw.TextStyle(font: font)),
  //       ),
  //     ],
  //   );
  // }

  static String _formatValue(String title, dynamic value) {
    if (value is num) {
      if (title == 'Total Rent' ||
          title == 'Extra Services' ||
          title == 'Additional Charges' ||
          title == 'Total Amount' ||
          title == 'Total with Tax' ||
          title == 'Discount' ||
          title == 'Advance Paid') {
        return '₹${value.toStringAsFixed(2)}';
      } else if (title == 'State GST' || title == 'Central GST') {
        return '${value.toString()}%';
      } else {
        return value.toString();
      }
    } else {
      return value.toString();
    }
  }

  // static pw.Widget _buildSectionTitle(String title, pw.Font font) {
  //   return pw.Text(
  //     title,
  //     style: pw.TextStyle(
  //       font: font,
  //       fontSize: 18,
  //       fontWeight: pw.FontWeight.bold,
  //       color: PdfColors.blueGrey,
  //     ),
  //   );
  // }

  Widget _buildTableRow(String title, dynamic value) {
    String displayValue = _formatValue(title, value);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 6, child: Text(displayValue)),
        ],
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout Details"),
        backgroundColor: const Color.fromARGB(255, 245, 129, 86),
        actions: [
          IconButton(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTitle("Room Information"),
            _buildTableRow("Room No", report['roomNo']),
            _buildTableRow("Room Type", report['roomType']),
            _buildTableRow("Check-in Date", report['checkinDate']),
            _buildTableRow("Check-in Time", report['checkinTime']),
            _buildTableRow("Check-out Date", report['checkoutDate']),
            _buildTableRow("Check-out Time", report['checkoutTime']),
            const SizedBox(height: 16),
            _buildTitle("Financial Summary"),
            _buildTableRow("Total Days Stayed", report['totalDaysStayed']),
            _buildTableRow("Total Rent", report['totalRent']),
            _buildTableRow("Extra Services", report['extraserviceTotalAmount']),
            _buildTableRow("Additional Charges", report['additionalCharges']),
            _buildTableRow("Total Amount", report['totalAmount']),
            _buildTableRow("State GST", report['stateGST']),
            _buildTableRow("Central GST", report['centralGST']),
            _buildTableRow("Total with Tax", report['totalAmountIncludingTax']),
            _buildTableRow("Discount", report['discount']),
            _buildTableRow("Advance Paid", report['checkinAdvance']),
            const SizedBox(height: 16),
            _buildTitle("Other Remarks"),
            _buildTableRow("Remarks", report['remarks']),
          ],
        ),
      ),
    );
  }
}
