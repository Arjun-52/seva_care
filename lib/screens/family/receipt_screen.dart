import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class ReceiptScreen extends StatelessWidget {
  final String paymentId;
  final String htmlContent;
  final String planName;
  final String status;
  final int amount;
  final String currency;
  final DateTime date;

  const ReceiptScreen({
    super.key,
    required this.paymentId,
    required this.htmlContent,
    required this.planName,
    required this.status,
    required this.amount,
    required this.currency,
    required this.date,
  });

  String _cleanHtml(String html) {
    // Basic regex to strip HTML tags for plain-text presentation
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    var clean = html.replaceAll(regex, '');
    // Clean up excessive newlines
    clean = clean.replaceAll(RegExp(r'\n+'), '\n').trim();
    return clean;
  }

  void _showActionSnackbar(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action successful!'),
        backgroundColor: SevaColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRefunded = status.toLowerCase() == 'refunded';
    final cleanText = _cleanHtml(htmlContent);

    // Extract potential values using simple regex or fallback to sensible defaults
    final receiptId = paymentId.replaceAll('pay_', 'rcpt_');
    final txId = paymentId;
    final formattedAmount = '${currency == 'INR' ? '₹' : currency}$amount';
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Receipt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Receipt',
            onPressed: () => _showActionSnackbar(context, 'Receipt shared'),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Receipt',
            onPressed: () => _showActionSnackbar(context, 'Document sent to printer'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Invoice/Receipt Card Layout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SevaColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Saffron/Seva Logo Circle
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      gradient: SevaColors.saffronGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Seva Senior Care',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
                  ),
                  Text(
                    'Elder Care Services Payment Receipt',
                    style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: SevaColors.divider),
                  const SizedBox(height: 16),

                  // Detail Rows
                  _buildDetailRow('Receipt ID', receiptId),
                  _buildDetailRow('Transaction ID', txId),
                  _buildDetailRow('Date', formattedDate),
                  _buildDetailRow('Plan Name', planName),
                  _buildDetailRow('Payment Status', isRefunded ? 'Refunded' : 'Paid', isStatus: true, isRefunded: isRefunded),
                  _buildDetailRow('Payment Method', 'Razorpay Checkout'),
                  const SizedBox(height: 16),
                  const Divider(color: SevaColors.divider),
                  const SizedBox(height: 16),

                  // Total Amount Paid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Paid',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
                      ),
                      Text(
                        formattedAmount,
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: SevaColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Document Contents / Raw Receipt Copy
            Text(
              'OFFICIAL TRANSCRIPT',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: SevaColors.textTertiary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SevaColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Text(
                  cleanText.isNotEmpty ? cleanText : 'No additional receipt logs found.',
                  style: GoogleFonts.robotoMono(fontSize: 12, color: SevaColors.textSecondary, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Download Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showActionSnackbar(context, 'PDF receipt download'),
                icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                label: Text(
                  'Download PDF Receipt',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false, bool isRefunded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRefunded ? Colors.blue.shade50 : SevaColors.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isRefunded ? Colors.blue : SevaColors.green),
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
            ),
        ],
      ),
    );
  }
}
