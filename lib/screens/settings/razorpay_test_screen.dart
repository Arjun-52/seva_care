import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../utils/theme.dart';
import '../../utils/app_logger.dart';

class RazorpayTestScreen extends StatefulWidget {
  const RazorpayTestScreen({super.key});

  @override
  State<RazorpayTestScreen> createState() => _RazorpayTestScreenState();
}

class _RazorpayTestScreenState extends State<RazorpayTestScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    AppLogger.i('Razorpay initialized on Test Screen');
  }

  @override
  void dispose() {
    _razorpay.clear();
    AppLogger.i('Razorpay cleared on Test Screen');
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final msg = "SUCCESS: Payment ID: ${response.paymentId}, Order ID: ${response.orderId}, Signature: ${response.signature}";
    AppLogger.i(msg);
    _showResultDialog("Payment Successful", msg, Colors.green);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final msg = "ERROR: Code: ${response.code}, Message: ${response.message}";
    AppLogger.e(msg);
    _showResultDialog("Payment Failed", msg, Colors.red);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final msg = "EXTERNAL WALLET: ${response.walletName}";
    AppLogger.i(msg);
    _showResultDialog("External Wallet Selected", msg, Colors.orange);
  }

  void _openCheckout() {
    final options = <String, dynamic>{
      'key': 'rzp_test_SgTgIrRTm5fJjb',
      'amount': 100, // ₹1.00
      'name': 'Seva Care',
      'description': 'Test Payment',
      'theme': {'color': '#3F51B5'},
      'prefill': {
        'contact': '9876543210',
        'email': 'test@sevacare.com',
        'name': 'Rishi Test User'
      }
    };

    AppLogger.i('Opening Razorpay options: $options');
    try {
      _razorpay.open(options);
    } catch (e, st) {
      AppLogger.e('Failed to open Razorpay checkout', e, st);
    }
  }

  void _showResultDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: color)),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Razorpay Payment Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment, size: 80, color: SevaColors.primary),
              const SizedBox(height: 24),
              Text(
                'Razorpay Gateway Test',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Launch a test payment of ₹1.00 below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _openCheckout,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Pay ₹1 Now',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
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
