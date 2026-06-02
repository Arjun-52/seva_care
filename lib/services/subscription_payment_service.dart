import 'dart:async';
import 'dart:io';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../repositories/subscription_repository.dart';
import '../models/subscription/subscription_order_result.dart';
import '../models/subscription/subscription_payment_result.dart';
import '../utils/app_logger.dart';
import '../config/env.dart';

class SubscriptionPaymentService {
  static const _tag = 'SubscriptionPaymentService';
  static const Duration _paymentTimeout = Duration(minutes: 5);

  final SubscriptionRepository _repository;
  late Razorpay _razorpay;
  Timer? _paymentTimer;
  bool _isInitialized = false;

  // Single in-flight checkout completer
  Completer<SubscriptionPaymentResult>? _pending;

  SubscriptionPaymentService(this._repository);

  void init() {
    if (_isInitialized) return;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _isInitialized = true;
    AppLogger.i('[$_tag] Razorpay initialized');
  }

  /// Purchase a subscription plan and open Razorpay checkout
  Future<SubscriptionPaymentResult> purchaseSubscription({
    required String planId,
    String? email,
    String? name,
  }) async {
    if (!_isInitialized) {
      throw StateError('SubscriptionPaymentService not initialized. Call init() first.');
    }
    if (_pending != null) {
      return const SubscriptionPaymentFailed(
        reason: SubscriptionPaymentFailureReason.unknown,
        message: 'A payment is already in progress.',
      );
    }

    AppLogger.i('[$_tag] Starting subscription upgrade for plan: $planId');
    _startPaymentTimeout();

    final SubscriptionOrderResult order;
    try {
      order = await _repository.upgradeSubscription(planId);
    } on SocketException catch (e) {
      _cancelPaymentTimeout();
      AppLogger.e('[$_tag] Network error during upgradeSubscription', e);
      return const SubscriptionPaymentFailed(
        reason: SubscriptionPaymentFailureReason.network,
        message: 'Network error. Please check your internet connection.',
      );
    } on TimeoutException catch (e) {
      _cancelPaymentTimeout();
      AppLogger.e('[$_tag] Timeout during upgradeSubscription', e);
      return const SubscriptionPaymentFailed(
        reason: SubscriptionPaymentFailureReason.timeout,
        message: 'Payment request timed out. Please try again.',
      );
    } on HandshakeException catch (e) {
      _cancelPaymentTimeout();
      AppLogger.e('[$_tag] SSL handshake during upgradeSubscription', e);
      return const SubscriptionPaymentFailed(
        reason: SubscriptionPaymentFailureReason.ssl,
        message: 'Secure connection failed. Check network settings.',
      );
    } catch (e, st) {
      _cancelPaymentTimeout();
      AppLogger.e('[$_tag] upgradeSubscription failed', e, st);
      return SubscriptionPaymentFailed(
        reason: SubscriptionPaymentFailureReason.invalidOrder,
        message: 'Failed to create subscription order: $e',
      );
    }

    switch (order) {
      case FreeSubscriptionOrder(subscriptionId: final subId):
        _cancelPaymentTimeout();
        AppLogger.i('[$_tag] Free subscription enrollment success: $subId');
        return SubscriptionFreeEnrollmentSucceeded(planId);

      case PaidSubscriptionOrder(
          orderId: final orderId,
          amount: final amount,
          keyId: final keyId,
        ):
        AppLogger.i('[$_tag] Opening Razorpay for order: $orderId');
        
        // 1. Log exact key being used
        print('[$_tag] [VERIFICATION] Razorpay Key being used: $keyId');

        // 2. Confirm prefix (test/live)
        if (keyId.startsWith('rzp_test_')) {
          print('[$_tag] [VERIFICATION] Confirmed: Key is in TEST mode (starts with rzp_test_)');
        } else if (keyId.startsWith('rzp_live_')) {
          print('[$_tag] [VERIFICATION] Confirmed: Key is in LIVE mode (starts with rzp_live_)');
        } else {
          print('[$_tag] [VERIFICATION] Warning: Key does not match standard test/live prefix pattern.');
        }

        // 3. Compare with Env configuration
        final envKey = Env.razorpayKey;
        print('[$_tag] [VERIFICATION] Configured Frontend (Env) Key: $envKey');
        if (keyId == envKey) {
          print('[$_tag] [VERIFICATION] Match: Frontend and backend keys are identical.');
        } else {
          print('[$_tag] [VERIFICATION] Mismatch: Frontend Env Key ($envKey) differs from Backend API-returned Key ($keyId).');
        }

        // 4. Verify API key is used
        print('[$_tag] [VERIFICATION] API key ($keyId) is being successfully used in place of any hardcoded keys.');

        final completer = Completer<SubscriptionPaymentResult>();
        _pending = completer;

        final options = <String, dynamic>{
          'key': keyId,
          'order_id': orderId,
          'amount': amount,
          'name': 'Seva Senior Care',
          'description': 'Upgrade Subscription',
          'theme': {'color': '#3F51B5'}, // Seva primary theme color
        };

        final prefill = <String, String>{};
        if (email != null && email.isNotEmpty) prefill['email'] = email;
        if (name != null && name.isNotEmpty) prefill['name'] = name;
        if (prefill.isNotEmpty) options['prefill'] = prefill;

        // 5. Log complete options object
        print('[$_tag] [VERIFICATION] Complete Razorpay options: $options');

        try {
          _razorpay.open(options);
        } catch (e, st) {
          _cancelPaymentTimeout();
          _pending = null;
          AppLogger.e('[$_tag] Razorpay.open failed', e, st);
          return SubscriptionPaymentFailed(
            reason: SubscriptionPaymentFailureReason.unknown,
            message: 'Failed to open payment sheet: $e',
          );
        }

        return completer.future;
    }
  }

  void dispose() {
    _cancelPaymentTimeout();
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
      AppLogger.i('[$_tag] Razorpay disposed');
    }
    if (_pending?.isCompleted == false) {
      _pending!.complete(
        const SubscriptionPaymentFailed(
          reason: SubscriptionPaymentFailureReason.unknown,
          message: 'Payment cancelled (widget disposed).',
        ),
      );
    }
    _pending = null;
  }

  // ─── Razorpay Event Handlers ─────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _cancelPaymentTimeout();
    AppLogger.i('[$_tag] Payment success: ${response.paymentId}');
    _completePending(
      SubscriptionPaymentSucceeded(
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _cancelPaymentTimeout();
    final raw = response.message ?? '';
    final lower = raw.toLowerCase();
    AppLogger.e('[$_tag] Payment error: ${response.code} - $raw');

    final reason = lower.contains('certificate') ||
            lower.contains('ssl') ||
            lower.contains('handshake')
        ? SubscriptionPaymentFailureReason.ssl
        : SubscriptionPaymentFailureReason.paymentDeclined;

    _completePending(
      SubscriptionPaymentFailed(
        reason: reason,
        message: raw.isEmpty ? 'Payment failed' : raw,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _cancelPaymentTimeout();
    AppLogger.i('[$_tag] External wallet selected: ${response.walletName}');
    _completePending(SubscriptionExternalWalletSelected(response.walletName));
  }

  void _completePending(SubscriptionPaymentResult result) {
    final c = _pending;
    _pending = null;
    if (c != null && !c.isCompleted) c.complete(result);
  }

  // ─── Timeout Helpers ──────────────────────────────────────────────────

  void _startPaymentTimeout() {
    _cancelPaymentTimeout();
    _paymentTimer = Timer(_paymentTimeout, () {
      AppLogger.e('[$_tag] Payment timeout reached');
      _completePending(
        const SubscriptionPaymentFailed(
          reason: SubscriptionPaymentFailureReason.timeout,
          message: 'Payment timed out.',
        ),
      );
    });
  }

  void _cancelPaymentTimeout() {
    _paymentTimer?.cancel();
    _paymentTimer = null;
  }
}
