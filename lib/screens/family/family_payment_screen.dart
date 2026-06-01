import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../utils/app_logger.dart';
import '../../core/storage/local_storage_service.dart';
import '../../repositories/subscription_repository.dart';
import '../../services/dependency_injection.dart';


class FamilyPaymentScreen extends StatefulWidget {
  final String orderId;
  final int amount; // in Razorpay smallest unit (e.g. 299900)
  final String currency;
  final String subscriptionId;
  final String paymentId;
  final String planName;

  const FamilyPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.subscriptionId,
    required this.paymentId,
    required this.planName,
  });

  @override
  State<FamilyPaymentScreen> createState() => _FamilyPaymentScreenState();
}

class _FamilyPaymentScreenState extends State<FamilyPaymentScreen> {
  int _selectedMethod = 0; // 0: Card, 1: UPI, 2: Netbanking
  bool _processing = false;

  final List<Map<String, dynamic>> _methods = [
    {
      'icon': Icons.credit_card_outlined,
      'title': 'Credit / Debit Card',
      'subtitle': 'Visa, Mastercard, RuPay',
    },
    {
      'icon': Icons.account_balance_wallet_outlined,
      'title': 'UPI / Google Pay / PhonePe',
      'subtitle': 'Pay instantly using UPI app',
    },
    {
      'icon': Icons.account_balance_outlined,
      'title': 'Net Banking',
      'subtitle': 'All major Indian banks supported',
    },
  ];

  Future<void> _processPayment() async {
    setState(() => _processing = true);
    AppLogger.i('Payment processing started for order: ${widget.orderId}');

    // Mock payment gateway delay
    await Future.delayed(const Duration(seconds: 2));

    AppLogger.i('Payment success captured. Subscription ID: ${widget.subscriptionId}, Payment ID: ${widget.paymentId}');

    if (mounted) {
      _performVerification();
    }
  }

  void _performVerification() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => WillPopScope(
        onWillPop: () async => false, // Disable back navigation
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: SevaColors.primary),
                const SizedBox(height: 20),
                Text(
                  'Verifying payment...',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    _callVerifyPaymentApi();
  }

  Future<void> _callVerifyPaymentApi() async {
    try {
      final repo = locator<SubscriptionRepository>();
      final result = await repo.verifyPayment(widget.subscriptionId, widget.paymentId);

      // Close the verifying payment dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (result.verified) {
        // Success flow: Store keys in LocalStorage
        final storage = locator<LocalStorageService>();
        await storage.setString('activeSubscriptionId', widget.subscriptionId);
        await storage.setString('activePlanName', widget.planName);
        await storage.setString('activePlanStatus', 'active');
        await storage.setString('activationDate', DateTime.now().toIso8601String());
        await storage.remove('pending_subscription_id');
        await storage.remove('pending_payment_id');

        AppLogger.i('Payment verified successfully');
        _showSuccessDialog();
      } else {
        AppLogger.e('Verification failed');
        _showFailureDialog(
          'Payment verification failed. Please contact support if amount was deducted.',
        );
      }
    } catch (e, stack) {
      // Close the loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      String errorMsg = 'Payment verification failed. Please try again.';
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        errorMsg = 'Unable to verify payment. Please check your internet connection.';
        AppLogger.e('Unable to verify payment. Please check your internet connection.', e, stack);
      } else {
        AppLogger.e('Payment verification failed. Please try again.', e, stack);
      }

      _showFailureDialog(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: SevaColors.redLight, shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline, size: 54, color: SevaColors.red),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verification Failed',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Plans',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _processing = true);
                          _performVerification();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: SevaColors.greenLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, size: 54, color: SevaColors.green),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Subscription activated successfully',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop dialog and pop payment screen returning true to reload subscription state
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Back to Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Original amount from backend is 299900 (smallest unit). Display standard currency is ₹2999.
    final displayPrice = widget.amount / 100;
    
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Checkout & Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Text('Order Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
            const SizedBox(height: 10),
            SevaCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.planName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Order: ${widget.orderId}', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                        ],
                      ),
                      Text(
                        '₹${displayPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: SevaColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: SevaColors.divider),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Billing Period', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
                      Text('Monthly', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods
            Text('Select Payment Method', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
            const SizedBox(height: 10),
            Column(
              children: List.generate(_methods.length, (index) {
                final m = _methods[index];
                final isSelected = _selectedMethod == index;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SevaCard(
                    padding: EdgeInsets.zero,
                    onTap: _processing ? null : () => setState(() => _selectedMethod = index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? SevaColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? SevaColors.primaryLight : SevaColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(m['icon'] as IconData, size: 20, color: isSelected ? SevaColors.primary : SevaColors.textSecondary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['title'] as String,
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m['subtitle'] as String,
                                  style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Radio<int>(
                            value: index,
                            groupValue: _selectedMethod,
                            activeColor: SevaColors.primary,
                            onChanged: _processing ? null : (val) => setState(() => _selectedMethod = val ?? 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _processing ? null : SevaColors.sevaGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _processing
                      ? []
                      : [
                          BoxShadow(
                            color: SevaColors.primary.withAlpha(76),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _processing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _processing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Pay ₹${displayPrice.toStringAsFixed(0)} Now',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: SevaColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by Razorpay. 256-bit encryption.',
                    style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
