// bills_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bills_provider.dart';
import '../models/bill_model.dart';
import '../utilities/route_manager.dart';
import '../utilities/constants.dart';
import '../widgets/bills_shimmer_loading.dart';
import '../services/pdf_service.dart';
import 'dart:io';

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) {
  return Color.fromRGBO(
    color.r.toInt(),
    color.g.toInt(),
    color.b.toInt(),
    opacity,
  );
}

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBills();
    });
  }

  Future<void> _fetchBills() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final billsProvider = Provider.of<BillsProvider>(context, listen: false);
      await billsProvider.fetchBills(authProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading bills: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billsProvider = Provider.of<BillsProvider>(context);
    final bills = billsProvider.bills;
    final totalUnpaid = billsProvider.totalUnpaidAmount;
    final totalMargin = billsProvider.totalBillsMargin;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FD,
      ), // Light blue-gray background for modern look
      body: RefreshIndicator(
        onRefresh: _fetchBills,
        child:
            billsProvider.isLoading
                ? const BillsShimmerLoadingEffect()
                : billsProvider.error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Constants.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${billsProvider.error}',
                        style: const TextStyle(
                          color: Constants.errorColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchBills,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : bills.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Colors.grey.shade400,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bills found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your bills will appear here when available',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight:
                            MediaQuery.of(context).size.height *
                            0.38, // Significantly increased responsive height
                        pinned: true,
                        backgroundColor: Constants.primaryColor,
                        elevation: innerBoxIsScrolled ? 4 : 0,
                        leading: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: withValues(Colors.white, 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
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
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _fetchBills,
                            ),
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          title: null, // Remove default title
                          centerTitle: true,
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
                                  children: [
                                    // Custom positioned title
                                    const Text(
                                      'My Bills',
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

                                    // Compact header with logo and title in a row
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Row(
                                        children: [
                                          // Logo container
                                          Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: withValues(
                                                    Colors.black,
                                                    0.1,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.receipt_long_rounded,
                                              size: 30,
                                              color: Constants.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          // Title and subtitle
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Billing Management',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: withValues(
                                                    Colors.white,
                                                    0.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Smart Tank',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Summary cards - more compact
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Row(
                                        children: [
                                          // Current bill card
                                          Expanded(
                                            child: _buildSummaryCard(
                                              title: 'Current Bill',
                                              amount: totalUnpaid,
                                              icon: Icons.receipt,
                                              iconColor: Colors.white,
                                              backgroundColor:
                                                  Colors.transparent,
                                              borderColor: withValues(
                                                Colors.white,
                                                0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Total margin card
                                          Expanded(
                                            child: _buildSummaryCard(
                                              title: 'Total Margin',
                                              amount: totalMargin,
                                              icon:
                                                  Icons.account_balance_wallet,
                                              iconColor: Colors.white,
                                              backgroundColor:
                                                  Colors.transparent,
                                              borderColor: withValues(
                                                Colors.white,
                                                0.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          collapseMode: CollapseMode.parallax,
                        ),
                      ),
                    ];
                  },
                  body: Column(
                    children: [
                      // Filter options - more compact
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: withValues(
                                      Constants.primaryColor,
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.history,
                                    color: Constants.primaryColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Billing History',
                                  style: TextStyle(
                                    color: Constants.blackColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: withValues(Constants.primaryColor, 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: withValues(
                                    Constants.primaryColor,
                                    0.2,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: Constants.primaryColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'All Bills',
                                    style: TextStyle(
                                      color: Constants.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bills list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bills.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final bill = bills[index];
                            return _buildBillCard(bill);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    Color? borderColor,
  }) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // More compact, integrated design
    return Container(
      height:
          isSmallScreen
              ? 90
              : 95, // Significantly increased height to fix overflow
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 6 : 8,
        horizontal: isSmallScreen ? 8 : 10,
      ),
      decoration: BoxDecoration(
        // Subtle glass-like effect
        color: withValues(Colors.white, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? withValues(Colors.white, 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Floating icon with subtle shadow
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: withValues(Colors.white, 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          // Title and amount in column - simplified layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.max, // Take all available space
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Distribute space evenly
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Slightly smaller font
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(Bill bill) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final statusColor =
        bill.status == 'Paid' ? Constants.successColor : Constants.errorColor;
    final statusBgColor =
        bill.status == 'Paid'
            ? Color.fromRGBO(
              56,
              142,
              60,
              38, // Increased alpha for better visibility
            )
            : Color.fromRGBO(
              211,
              47,
              47,
              38, // Increased alpha for better visibility
            );

    // Define gradient colors based on bill status
    final List<Color> gradientColors =
        bill.status == 'Paid'
            ? [
              const Color(0xFFEBF7EE), // Light green background for paid bills
              Colors.white,
            ]
            : [
              const Color(0xFFF0F7FF), // Light blue background for unpaid bills
              Colors.white,
            ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withAlpha(40), width: 0.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: gradientColors,
          ),
        ),
        child: Column(
          children: [
            // Bill header
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              bill.status == 'Paid'
                                  ? const Color(
                                    0xFFE8F5E9,
                                  ) // Light green for paid
                                  : const Color(
                                    0xFFE3F2FD,
                                  ), // Light blue for unpaid
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.receipt_outlined,
                          color:
                              bill.status == 'Paid'
                                  ? Constants.successColor
                                  : Constants.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bill.monthName} ${bill.year}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bill #${bill.id.substring(bill.id.length - 6)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      bill.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bill details
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withAlpha(30),
                  width: 0.5,
                ),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Water Usage',
                    '${bill.amount} L',
                    icon: Icons.water_drop,
                  ),
                  _buildInfoRow(
                    'Price for Water',
                    '\$${bill.priceForLetters.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                  ),
                  _buildInfoRow(
                    'Fees',
                    '\$${bill.fees.toStringAsFixed(2)}',
                    icon: Icons.account_balance,
                  ),
                  Divider(height: 24, color: Colors.grey.withAlpha(100)),
                  _buildInfoRow(
                    'Total',
                    '\$${bill.totalPrice.toStringAsFixed(2)}',
                    isBold: true,
                    icon: Icons.summarize,
                  ),
                ],
              ),
            ),

            // Bill actions
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 12 : 16,
              ),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (bill.status == 'Unpaid')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteManager.paymentRoute,
                          arguments: bill,
                        );
                      },
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Constants.primaryColor.withAlpha(100),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteManager.billDetailsRoute,
                          arguments: bill,
                        );
                      },
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('View Receipt'),
                      style: TextButton.styleFrom(
                        foregroundColor: Constants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _downloadBillAsPdf(bill),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadBillAsPdf(Bill bill) async {
    // Store context before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Show loading indicator
      _showLoadingDialog('Generating PDF...');

      // Generate PDF
      final File pdfFile = await PdfService.generateBillPdf(bill);

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Hide loading indicator
      navigator.pop();

      // Show success message
      _showSuccessDialog(pdfFile);
    } catch (e) {
      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Hide loading indicator if showing
      if (navigator.canPop()) {
        navigator.pop();
      }

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
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
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
          title: const Text('PDF Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your bill has been successfully converted to PDF.'),
              const SizedBox(height: 16),
              Text(
                'File saved to: ${pdfFile.path}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CLOSE'),
            ),
            TextButton.icon(
              onPressed: () async {
                // Store context before async gap
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();

                // Show a success message
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('PDF file saved successfully'),
                      backgroundColor: Constants.successColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download_done),
              label: const Text('SAVE'),
              style: TextButton.styleFrom(
                foregroundColor: Constants.successColor,
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
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('VIEW'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    IconData? icon,
  }) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmallScreen ? 14 : 16,
              color: isBold ? Constants.primaryColor : Colors.grey.shade600,
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize:
                  isBold
                      ? (isSmallScreen ? 14 : 16)
                      : (isSmallScreen ? 13 : 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black : Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize:
                  isBold
                      ? (isSmallScreen ? 16 : 18)
                      : (isSmallScreen ? 13 : 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? Constants.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
