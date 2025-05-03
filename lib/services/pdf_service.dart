import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/bill_model.dart';

class PdfService {
  static Future<File> generateBillPdf(Bill bill) async {
    final pdf = pw.Document();

    // Logo placeholder instead of loading image
    // This avoids image loading issues
    final pw.Widget logoWidget = pw.Container(
      width: 100,
      height: 40,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('1976D2'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Center(
        child: pw.Text(
          'Smart Water',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );

    // Format date
    final DateFormat dateFormat = DateFormat('MMMM dd, yyyy');
    final String formattedDate = dateFormat.format(DateTime.now());

    // Define colors
    final PdfColor primaryColor = PdfColor.fromHex('1976D2'); // Primary color
    final PdfColor successColor = PdfColor.fromHex(
      '388E3C',
    ); // Constants.successColor
    final PdfColor errorColor = PdfColor.fromHex(
      'D32F2F',
    ); // Constants.errorColor

    // Status color
    final PdfColor statusColor =
        bill.status == 'Paid' ? successColor : errorColor;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  logoWidget,
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'WATER BILL',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Bill #${bill.id.substring(bill.id.length - 6)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on $formattedDate',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Bill information
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Billing Period:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${bill.monthName} ${bill.year}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: statusColor.shade(0.1),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(16),
                          ),
                          border: pw.Border.all(color: statusColor),
                        ),
                        child: pw.Text(
                          bill.status,
                          style: pw.TextStyle(
                            color: statusColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Customer information
            pw.Text(
              'CUSTOMER INFORMATION',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  _buildInfoRow(
                    'Customer ID:',
                    'CUST-${bill.id.substring(0, 6)}',
                  ),
                  _buildInfoRow(
                    'Name:',
                    'Customer Name',
                  ), // Replace with actual customer name
                  _buildInfoRow(
                    'Address:',
                    'Customer Address',
                  ), // Replace with actual address
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Bill details
            pw.Text(
              'BILL DETAILS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  _buildBillDetailRow(
                    'Water Usage:',
                    '${bill.amount} L',
                    false,
                  ),
                  _buildBillDetailRow(
                    'Price for Water:',
                    '\$${bill.priceForLetters.toStringAsFixed(2)}',
                    false,
                  ),
                  _buildBillDetailRow(
                    'Fees:',
                    '\$${bill.fees.toStringAsFixed(2)}',
                    false,
                  ),
                  pw.Divider(color: PdfColors.grey300),
                  _buildBillDetailRow(
                    'Total:',
                    '\$${bill.totalPrice.toStringAsFixed(2)}',
                    true,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Payment information
            pw.Text(
              'PAYMENT INFORMATION',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Payment Status:', bill.status),
                  if (bill.status == 'Paid')
                    _buildInfoRow(
                      'Payment Date:',
                      'Payment date',
                    ), // Replace with actual payment date
                  if (bill.status == 'Unpaid')
                    _buildInfoRow(
                      'Due Date:',
                      'Due date',
                    ), // Replace with actual due date
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Payment Methods:',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '• Online Payment through the Smart Water System App',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '• Bank Transfer to Account #: 123-456-789',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Thank you note
            pw.Center(
              child: pw.Text(
                'Thank you for using our Smart Water System!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'For any inquiries, please contact support@smartwater.com',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save the PDF
    return await savePdf(
      'water_bill_${bill.monthName.toLowerCase()}_${bill.year}.pdf',
      pdf,
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillDetailRow(
    String label,
    String value,
    bool isBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: isBold ? PdfColors.black : PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? pw.FontWeight.bold : null,
              color: isBold ? PdfColors.black : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> savePdf(String fileName, pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> openPdf(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open the file: ${result.message}');
    }
  }
}
