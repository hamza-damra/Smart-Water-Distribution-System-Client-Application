import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mytank/models/bill_model.dart';
import 'package:mytank/services/pdf_service.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/auth_provider.dart';

class BillDetailsScreen extends StatefulWidget {
  final Bill bill;

  const BillDetailsScreen({super.key, required this.bill});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  bool isLoading = false;

  // Helper method to replace deprecated withOpacity
  Color withValues(Color color, double opacity) => Color.fromRGBO(
    color.r.toInt(),
    color.g.toInt(),
    color.b.toInt(),
    opacity,
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userName ?? "User";
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Format dates
    final DateFormat dateFormat = DateFormat('MMMM dd, yyyy');
    final String createdDate = dateFormat.format(widget.bill.createdAt);
    final String updatedDate = dateFormat.format(widget.bill.updatedAt);

    // Status color
    final statusColor =
        widget.bill.status == 'Paid'
            ? Constants.successColor
            : Constants.errorColor;

    final statusBgColor =
        widget.bill.status == 'Paid'
            ? withValues(Constants.successColor, 0.1)
            : withValues(Constants.errorColor, 0.1);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FD,
      ), // Light blue-gray background for modern look
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with gradient background
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.32,
            pinned: true,
            stretch: true,
            backgroundColor: Constants.primaryColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: withValues(Colors.white, 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: withValues(Colors.white, 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => _downloadBillAsPdf(widget.bill),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E3A8A), // Deeper blue
                      Constants.primaryColor,
                      Constants.secondaryColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Custom positioned title
                        const Text(
                          'Bill Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: withValues(Colors.white, 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Smart Tank',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bill ID and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: withValues(Colors.white, 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Bill #${widget.bill.id.substring(widget.bill.id.length - 6)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    widget.bill.status == 'Paid'
                                        ? withValues(
                                          Constants.successColor,
                                          0.3,
                                        )
                                        : withValues(Constants.errorColor, 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.bill.status == 'Paid'
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.bill.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Total amount
                        Text(
                          '\$${widget.bill.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Billing period
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: withValues(Colors.white, 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.bill.monthName} ${widget.bill.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bill details card
                  _buildSectionCard(
                    title: 'BILL DETAILS',
                    icon: Icons.receipt_outlined,
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Water Usage',
                          '${widget.bill.amount.toStringAsFixed(0)} L',
                          icon: Icons.water_drop_outlined,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Price for Water',
                          '\$${widget.bill.priceForLetters.toStringAsFixed(2)}',
                          icon: Icons.attach_money_outlined,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Fees',
                          '\$${widget.bill.fees.toStringAsFixed(2)}',
                          icon: Icons.account_balance_outlined,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Total Amount',
                          '\$${widget.bill.totalPrice.toStringAsFixed(2)}',
                          isTotal: true,
                          icon: Icons.summarize_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment information card
                  _buildSectionCard(
                    title: 'PAYMENT INFORMATION',
                    icon: Icons.payment,
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Status',
                          widget.bill.status,
                          valueColor:
                              widget.bill.status == 'Paid'
                                  ? Constants.successColor
                                  : Constants.errorColor,
                          icon:
                              widget.bill.status == 'Paid'
                                  ? Icons.check_circle_outline
                                  : Icons.pending_outlined,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Payment Date',
                          widget.bill.status == 'Paid'
                              ? updatedDate
                              : 'Not paid yet',
                          icon: Icons.calendar_today_outlined,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Bill Generated',
                          createdDate,
                          icon: Icons.date_range_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Customer information card
                  _buildSectionCard(
                    title: 'CUSTOMER INFORMATION',
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Customer Name',
                          userName,
                          icon: Icons.person_outlined,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Customer ID',
                          'CUST-${widget.bill.customer.substring(0, 6)}',
                          icon: Icons.badge_outlined,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Tank ID',
                          'TANK-${widget.bill.tank.substring(0, 6)}',
                          icon: Icons.water_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadBillAsPdf(widget.bill),
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text(
                            'DOWNLOAD PDF',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: withValues(Constants.primaryColor, 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: withValues(Constants.primaryColor, 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Constants.primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Constants.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: withValues(Constants.primaryColor, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: Constants.primaryColor),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? Constants.blackColor : Constants.greyColor,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color:
                  valueColor ??
                  (isTotal ? Constants.blackColor : Constants.blackColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadBillAsPdf(Bill bill) async {
    // Store context references before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      isLoading = true;
    });

    try {
      // Show loading indicator
      _showLoadingDialog('Generating PDF...');

      // Generate PDF
      final File pdfFile = await PdfService.generateBillPdf(bill);

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Hide loading indicator
      navigator.pop();

      setState(() {
        isLoading = false;
      });

      // Show success dialog
      _showSuccessDialog(pdfFile);
    } catch (e) {
      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Hide loading indicator if showing
      if (navigator.canPop()) {
        navigator.pop();
      }

      setState(() {
        isLoading = false;
      });

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Constants.errorColor,
        ),
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Constants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(File pdfFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: withValues(Constants.successColor, 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Constants.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PDF Generated',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your bill has been successfully converted to PDF.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: withValues(Constants.primaryColor, 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: withValues(Constants.primaryColor, 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: Constants.greyColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pdfFile.path,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Constants.greyColor,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Constants.greyColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'CLOSE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Store context before async gap
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();

                try {
                  await PdfService.openPdf(pdfFile);
                } catch (e) {
                  // Check if widget is still mounted before using stored scaffoldMessenger
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error opening PDF: ${e.toString()}'),
                        backgroundColor: Constants.errorColor,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text(
                'VIEW PDF',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                elevation: 0,
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        );
      },
    );
  }
}
