import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../../core/api/api_client.dart';
import '../../services/dependency_injection.dart';
import '../../utils/app_logger.dart';
import '../../models/current_subscription_model.dart';
import '../../models/payment_history_model.dart';
import '../../repositories/subscription_repository.dart';
import '../../core/errors/failure.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/storage/local_storage_service.dart';
import '../../config/env.dart';
import 'receipt_screen.dart';




class FamilySubscription extends StatefulWidget {
  const FamilySubscription({super.key});

  @override
  State<FamilySubscription> createState() => _FamilySubscriptionState();
}

class _FamilySubscriptionState extends State<FamilySubscription> {
  final ScrollController _scrollController = ScrollController();
  
  bool _loading = false;
  List<SubscriptionPlan> _plans = [];
  CurrentSubscriptionModel? _currentSub;
  String? _error;
  List<PaymentHistoryModel> _payments = [];
  bool _paymentsLoading = false;
  String? _paymentsError;

  late Razorpay _razorpay;
  // subscriptionId captured from POST /v1/subscriptions/upgrade
  String? _activeUpgradeSubscriptionId;
  bool _paymentLoading = false;
  String? _paymentLoadingText;
  bool _cancelLoading = false;
  bool _refundLoading = false;
  bool _cancelPaymentLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchSubscriptionData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubscriptionData({bool isRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _paymentsLoading = true;
      _paymentsError = null;
    });

    if (isRefresh) {
      AppLogger.i('Refresh triggered');
    }
    AppLogger.i('Subscription plans fetch started');
    AppLogger.i('Current subscription fetch started');

    try {
      // Fetch plans, current active sub, and payments in parallel for maximum network efficiency
      final futures = await Future.wait([
        locator<ApiClient>().get('subscriptions/plans').catchError((e) {
          AppLogger.e('Plans fetch failed: $e');
          return ApiResult.error(ServerFailure('Unable to load plans'));
        }),
        locator<ApiClient>().get('subscriptions/current').catchError((e) {
          AppLogger.e('Current subscription fetch failed: $e');
          return ApiResult.error(ServerFailure('Unable to load current subscription'));
        }),
        locator<SubscriptionRepository>().getSubscriptionPayments().catchError((e) {
          AppLogger.e('Payments fetch failed: $e');
          if (mounted) {
            setState(() {
              _paymentsError = 'Unable to load payment history';
              _paymentsLoading = false;
            });
          }
          return <PaymentHistoryModel>[];
        }),
      ]);

      final plansResult = futures[0] as ApiResult;
      final currentResult = futures[1] as ApiResult;
      final fetchedPayments = futures[2] as List<PaymentHistoryModel>;

      AppLogger.i('API success');

      // 1. Process Current Subscription
      if (currentResult.success) {
        if (currentResult.data != null) {
          final activeSub = CurrentSubscriptionModel.fromJson(currentResult.data as Map<String, dynamic>);
          _currentSub = activeSub;
          AppLogger.i('Active subscription found: ${activeSub.planName}');
        } else {
          _currentSub = null;
          AppLogger.i('No active subscription found');
        }
      } else {
        AppLogger.e('Current subscription fetch failed: ${currentResult.errorMessage}');
      }

      // 2. Process Plans
      if (plansResult.success && plansResult.data != null) {
        final List<dynamic> dataList = plansResult.data as List<dynamic>;
        
        final List<SubscriptionPlan> fetchedPlans = [];
        int popularCount = 0;
        
        for (var e in dataList) {
          final plan = SubscriptionPlan.fromJson(e as Map<String, dynamic>);
          if (plan.active) {
            // Evaluates current plan status dynamically matching active sub from API
            final isCurrent = _currentSub != null && plan.name.toLowerCase() == _currentSub!.planName.toLowerCase();
            final finalizedPlan = SubscriptionPlan(
              id: plan.id,
              name: plan.name,
              price: plan.price,
              period: plan.period,
              features: plan.features,
              isCurrent: isCurrent,
              isPopular: plan.isPopular,
              maxSeniors: plan.maxSeniors,
              active: plan.active,
              createdAt: plan.createdAt,
            );
            
            fetchedPlans.add(finalizedPlan);
            if (plan.isPopular) {
              popularCount++;
              AppLogger.i('Popular plan detected: ${plan.name}');
            }
          }
        }

        AppLogger.i('Plans count received: ${fetchedPlans.length} (Popular detected: $popularCount)');

        if (fetchedPlans.isEmpty) {
          AppLogger.i('Empty response received');
        }

        if (mounted) {
          setState(() {
            _plans = fetchedPlans;
          });
        }
      } else {
        AppLogger.e('Plans fetch failed: ${plansResult.errorMessage}');
        if (mounted) {
          setState(() {
            _error = plansResult.errorMessage;
          });
        }
        _showErrorSnackbar(plansResult.errorMessage);
      }

      // 3. Process Payments
      fetchedPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _payments = fetchedPayments;
          _paymentsLoading = false;
        });
      }
      AppLogger.i('Current subscription refreshed');

    } catch (e, stack) {
      AppLogger.e('API error', e, stack);
      String displayError = 'Something went wrong. Please try again.';
      String paymentsErrorMsg = 'Something went wrong';
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        displayError = 'Unable to connect. Please check your internet connection.';
        paymentsErrorMsg = 'Unable to load payment history';
      }
      if (mounted) {
        setState(() {
          _error = displayError;
          _paymentsError = paymentsErrorMsg;
          _paymentsLoading = false;
        });
      }
      _showErrorSnackbar(displayError);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _paymentsLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: SevaColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _scrollToPlans() {
    _scrollController.animateTo(
      310.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: SevaColors.background,
          appBar: AppBar(title: const Text('Subscription Plans')),
          body: RefreshIndicator(
            onRefresh: () async {
              await _fetchSubscriptionData(isRefresh: true);
              AppLogger.i('Refresh completed');
            },
            color: SevaColors.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ─── Current Active Subscription Card ───
                _buildCurrentSubscriptionCard(),
                const SizedBox(height: 24),

                Text('Choose Your Plan', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Upgrade anytime. Cancel anytime.', style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
                const SizedBox(height: 20),

                // Dynamically Loaded Plans List
                _buildPlansSection(),
                const SizedBox(height: 24),

                // Payment history
                const SizedBox(height: 8),
                const SectionTitle(title: 'Payment History', icon: Icons.receipt_long),
                const SizedBox(height: 12),
                _buildPaymentHistorySection(),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ),
        if (_paymentLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: SevaColors.primary),
                        if (_paymentLoadingText != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _paymentLoadingText!,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    if (_loading && _currentSub == null) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(color: SevaColors.primary),
        ),
      );
    }

    // CASE 1: No Subscription State (null data)
    if (_currentSub == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SevaColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: SevaColors.redLight, shape: BoxShape.circle),
              child: const Icon(Icons.cancel_outlined, size: 36, color: SevaColors.red),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Subscription',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a subscription plan to start monitoring and caring for your loved ones.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _scrollToPlans,
                child: const Text('View Plans'),
              ),
            ),
          ],
        ),
      );
    }

    // CASE 2: Active Subscription State
    final sub = _currentSub!;
    final formattedPrice = '₹${sub.priceInr}';
    final formattedPeriod = sub.period.toLowerCase() == 'monthly' ? ' /month' : ' /${sub.period}';
    final isActive = sub.status.toLowerCase() == 'active';
    final isCancelled = sub.status.toLowerCase() == 'cancelled';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isCancelled
            ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : SevaColors.sevaGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCancelled ? Colors.grey : SevaColors.primary).withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'CURRENT PLAN',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? SevaColors.green.withAlpha(51)
                    : isCancelled
                        ? Colors.orange.withAlpha(80)
                        : SevaColors.red.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sub.status.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(sub.planName, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          isCancelled
              ? 'Cancelled • Access until: ${_formatDate(sub.endDate)}'
              : 'Active: ${_formatDate(sub.startDate)} | Renews: ${_formatDate(sub.endDate)}',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Text(formattedPrice, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(formattedPeriod, style: GoogleFonts.inter(fontSize: 14, color: Colors.white60)),
        ]),
        // Cancel button — only shown when subscription is active
        if (isActive) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _cancelLoading
                ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                : OutlinedButton(
                    onPressed: (_paymentLoading || _cancelLoading) ? null : () => _showCancelDialog(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54, width: 1.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel Subscription',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
          ),
        ],
        if (isCancelled)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white60, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your subscription is cancelled. You have access until the billing period ends.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white60, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _buildPlansSection() {
    if (_loading && _plans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: SevaColors.primary),
        ),
      );
    }

    if (_error != null && _plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: SevaColors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: SevaColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchSubscriptionData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Text(
                'No Subscription Plans Available',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Please check again later.',
                style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final isSubCancelled = _currentSub != null && _currentSub!.status.toLowerCase() == 'cancelled';

    return Column(
      children: _plans.map((plan) {
        final isPopular = plan.isPopular;
        final isCurrent = plan.isCurrent;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPopular ? SevaColors.primary : isCurrent ? SevaColors.green : SevaColors.border,
                width: isPopular || isCurrent ? 2 : 1,
              ),
              boxShadow: isPopular ? [BoxShadow(color: SevaColors.primary.withAlpha(30), blurRadius: 20, offset: const Offset(0, 6))] : null,
            ),
            child: Column(children: [
              // Header badge
              if (isPopular || isCurrent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isPopular ? SevaColors.primary : SevaColors.green,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                  ),
                  child: Center(child: Text(
                    isCurrent ? 'CURRENT PLAN' : 'MOST POPULAR',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                  )),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
                      const SizedBox(height: 6),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(plan.price, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: SevaColors.textPrimary)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(plan.period, style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textTertiary)),
                        ),
                      ]),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(color: SevaColors.divider),
                  const SizedBox(height: 12),

                  // Features
                  ...plan.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: isPopular ? SevaColors.primaryLight : SevaColors.greenLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, size: 12,
                          color: isPopular ? SevaColors.primary : SevaColors.green),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textPrimary, height: 1.3))),
                    ]),
                  )),
                  const SizedBox(height: 16),

                  // CTA Button
                  SizedBox(width: double.infinity, child: isCurrent
                    ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Current Plan', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: (isPopular && !isSubCancelled) ? SevaColors.sevaGradient : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: isSubCancelled ? null : () => _showUpgradeDialog(context, plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPopular
                                ? (isSubCancelled ? Colors.grey.shade300 : Colors.transparent)
                                : (isSubCancelled ? Colors.grey.shade300 : SevaColors.primary),
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isSubCancelled ? 'Unavailable' : 'Upgrade to ${plan.name}',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isSubCancelled ? Colors.grey.shade500 : Colors.white),
                          ),
                        ),
                      ),
                  ),
                ]),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentHistorySection() {
    if (_paymentsLoading && _payments.isEmpty) {
      return _buildPaymentHistorySkeleton();
    }

    if (_paymentsError != null && _payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SevaColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40, color: SevaColors.red),
            const SizedBox(height: 12),
            Text(
              _paymentsError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchSubscriptionData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SevaColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 40, color: SevaColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No payment history available',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: _scrollToPlans,
                child: const Text('Browse Plans'),
              ),
            ),
          ],
        ),
      );
    }

    return SevaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(_payments.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const Divider(height: 1, color: SevaColors.divider, indent: 16);
          }
          final paymentIndex = index ~/ 2;
          return _paymentRow(_payments[paymentIndex]);
        }),
      ),
    );
  }

  Widget _buildPaymentHistorySkeleton() {
    return SevaCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(5, (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 80, height: 12, color: Colors.grey.shade100),
                    const SizedBox(height: 6),
                    Container(width: 120, height: 10, color: Colors.grey.shade100),
                  ],
                ),
              ),
              Container(width: 60, height: 12, color: Colors.grey.shade100),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        bgColor = SevaColors.greenLight;
        textColor = SevaColors.green;
        label = 'Paid';
        break;
      case 'pending':
        bgColor = SevaColors.orangeLight;
        textColor = SevaColors.orange;
        label = 'Pending';
        break;
      case 'failed':
        bgColor = SevaColors.redLight;
        textColor = SevaColors.red;
        label = 'Failed';
        break;
      case 'cancelled':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = 'Cancelled';
        break;
      case 'refunded':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Refunded';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = status.toUpperCase();
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = date.month >= 1 && date.month <= 12 ? months[date.month - 1] : 'Jan';
    final year = date.year;
    
    int hour = date.hour;
    final isPm = hour >= 12;
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final period = isPm ? 'PM' : 'AM';
    
    return '$day $monthName $year\n$hourStr:$minuteStr $period';
  }

  Widget _paymentRow(PaymentHistoryModel payment) {
    final isSuccess = payment.status.toLowerCase() == 'paid' || payment.status.toLowerCase() == 'success';
    final isRefunded = payment.status.toLowerCase() == 'refunded';
    final isPending = payment.status.toLowerCase() == 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? SevaColors.greenLight
                      : isRefunded
                          ? Colors.blue.shade50
                          : SevaColors.orangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle
                      : isRefunded
                          ? Icons.keyboard_return
                          : Icons.pending,
                  size: 18,
                  color: isSuccess
                      ? SevaColors.green
                      : isRefunded
                          ? Colors.blue
                          : SevaColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.planName,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${payment.id}',
                      style: GoogleFonts.inter(fontSize: 10, color: SevaColors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(payment.createdAt),
                      style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${payment.currency == 'INR' ? '₹' : payment.currency}${payment.amount}',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusBadge(payment.status),
                ],
              ),
            ],
          ),
          if (isSuccess || isRefunded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: Row(
                children: [
                  if (isSuccess) ...[
                    SizedBox(
                      height: 28,
                      child: TextButton.icon(
                        onPressed: (_paymentLoading || _cancelLoading || _refundLoading || _cancelPaymentLoading)
                            ? null
                            : () => _showRefundDialog(context, payment),
                        icon: const Icon(Icons.keyboard_return, size: 14, color: SevaColors.primary),
                        label: Text(
                          'Request Refund',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.primary),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  SizedBox(
                    height: 28,
                    child: TextButton.icon(
                      onPressed: (_paymentLoading || _cancelLoading || _refundLoading || _cancelPaymentLoading)
                          ? null
                          : () => _fetchAndOpenReceipt(context, payment),
                      icon: const Icon(Icons.receipt_outlined, size: 14, color: SevaColors.primary),
                      label: Text(
                        'View Receipt',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.primary),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isPending) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: SizedBox(
                height: 28,
                child: TextButton.icon(
                  onPressed: (_paymentLoading || _cancelLoading || _refundLoading || _cancelPaymentLoading)
                      ? null
                      : () => _showCancelPaymentDialog(context, payment),
                  icon: const Icon(Icons.cancel_outlined, size: 14, color: SevaColors.red),
                  label: Text(
                    'Cancel Payment',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Upgrade to ${plan.name}?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Would you like to upgrade your subscription to ${plan.name}? You can create the plan directly or proceed to payment.',
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createNewSubscription(plan);
            },
            child: Text(
              'Create Plan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startUpgradeFlow(plan);
            },
            child: Text(
              'Pay Now',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: SevaColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Calls the repository to create a new subscription plan and handles loading, success, and error states.
  Future<void> _createNewSubscription(SubscriptionPlan plan) async {
    if (_paymentLoading) return;
    setState(() {
      _paymentLoading = true;
      _paymentLoadingText = 'Creating subscription...';
    });

    AppLogger.i('[CreateSubscription] Calling POST /v1/subscriptions with planId: ${plan.id}');
    try {
      final sub = await locator<SubscriptionRepository>().createSubscription(planId: plan.id);
      AppLogger.i('[CreateSubscription] Subscription created successfully: ${sub.id}');

      // Store returned data
      final storage = locator<LocalStorageService>();
      await storage.saveRememberMe(true); // Keep active session indicator

      _showSuccessDialog('Subscription Created', 'Subscription for ${plan.name} has been created successfully!');

      // Refresh current subscription details UI automatically
      await _fetchSubscriptionData(isRefresh: true);
    } catch (e, st) {
      AppLogger.e('[CreateSubscription] Failed', e, st);
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _showErrorSnackbar(errorMsg.isNotEmpty ? errorMsg : 'Failed to create subscription');
    } finally {
      if (mounted) {
        setState(() {
          _paymentLoading = false;
          _paymentLoadingText = null;
        });
      }
    }
  }

  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SevaColors.textPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: SevaColors.green, size: 28),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Great!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final razorpayPaymentId = response.paymentId ?? '';
    final razorpayOrderId   = response.orderId   ?? '';
    final razorpaySignature = response.signature ?? '';
    final subscriptionId    = _activeUpgradeSubscriptionId ?? '';

    AppLogger.i(
      '[Razorpay] Payment SUCCESS callback received:\n'
      '  razorpay_payment_id : $razorpayPaymentId\n'
      '  razorpay_order_id   : $razorpayOrderId\n'
      '  razorpay_signature  : $razorpaySignature\n'
      '  subscriptionId      : $subscriptionId',
    );

    if (subscriptionId.isEmpty) {
      AppLogger.e('[Razorpay] Cannot verify — subscriptionId is missing');
      _showErrorSnackbar('Verification error: missing subscription ID. Please contact support.');
      if (mounted) setState(() { _paymentLoading = false; _paymentLoadingText = null; });
      return;
    }

    if (razorpayPaymentId.isEmpty) {
      AppLogger.e('[Razorpay] Cannot verify — razorpay_payment_id is missing');
      _showErrorSnackbar('Verification error: missing payment ID. Please contact support.');
      if (mounted) setState(() { _paymentLoading = false; _paymentLoadingText = null; });
      return;
    }

    AppLogger.i('[Razorpay] Proceeding to verify-payment API');
    _verifyPayment(
      subscriptionId: subscriptionId,
      razorpayPaymentId: razorpayPaymentId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    AppLogger.e(
      '[Razorpay] Payment FAILURE callback received:\n'
      '  code    : ${response.code}\n'
      '  message : ${response.message}',
    );
    if (mounted) {
      setState(() {
        _paymentLoading = false;
        _paymentLoadingText = null;
        _activeUpgradeSubscriptionId = null;
      });
    }
    if (response.code == 2) {
      _showInfoSnackbar('Payment cancelled.');
    } else {
      _showErrorSnackbar('Payment failed: ${response.message ?? "Please try again."}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.i('[Razorpay] External wallet selected: ${response.walletName}');
    if (mounted) {
      setState(() {
        _paymentLoading = false;
        _paymentLoadingText = null;
        _activeUpgradeSubscriptionId = null;
      });
    }
  }

  Future<void> _verifyPayment({
    required String subscriptionId,
    required String razorpayPaymentId,
  }) async {
    setState(() {
      _paymentLoading = true;
      _paymentLoadingText = 'Verifying payment...';
    });

    AppLogger.i(
      '[VerifyPayment] Calling POST /v1/subscriptions/verify-payment:\n'
      '  subscriptionId    : $subscriptionId\n'
      '  razorpayPaymentId : $razorpayPaymentId',
    );

    try {
      final verified = await locator<SubscriptionRepository>().verifySubscriptionPayment(
        subscriptionId: subscriptionId,
        razorpayPaymentId: razorpayPaymentId,
      );

      AppLogger.i('[VerifyPayment] Response received — verified: $verified');

      if (verified) {
        // ── Payment confirmed ─────────────────────────────────────────────
        AppLogger.i('[VerifyPayment] Payment verified. Refreshing subscription...');
        setState(() { _paymentLoadingText = 'Refreshing subscription...'; });
        await _fetchSubscriptionData(isRefresh: true);
        AppLogger.i('[VerifyPayment] Subscription refreshed successfully');
        _showSuccessDialog('Payment Successful', 'Your subscription has been upgraded successfully!');
      } else {
        // ── verified: false ───────────────────────────────────────────────
        AppLogger.e('[VerifyPayment] Backend returned verified=false — subscription not activated');
        _showErrorSnackbar(
          'Payment verification pending. Your subscription will activate once confirmed. '
          'If the amount was deducted, please contact support.',
        );
      }
    } catch (e, st) {
      AppLogger.e('[VerifyPayment] Exception during verification', e, st);
      _showErrorSnackbar('Verification failed. Please contact support.');
    } finally {
      if (mounted) {
        setState(() {
          _paymentLoading = false;
          _paymentLoadingText = null;
          _activeUpgradeSubscriptionId = null;
        });
      }
    }
  }

  Future<void> _startUpgradeFlow(SubscriptionPlan plan) async {
    if (_loading || _paymentLoading) return;

    AppLogger.i('[Upgrade] Plan selected: "${plan.name}" | planId: ${plan.id}');
    setState(() {
      _paymentLoading = true;
      _paymentLoadingText = 'Initiating upgrade...';
    });

    try {
      AppLogger.i('[Upgrade] Calling POST /v1/subscriptions/upgrade');
      final result = await locator<SubscriptionRepository>().upgradeSubscription(plan.id);

      // ── Case 1: Scheduled downgrade ─────────────────────────────────────
      if (!result.isImmediate) {
        AppLogger.i('[Upgrade] Scheduled response received: ${result.message}');
        if (mounted) {
          setState(() {
            _paymentLoading = false;
            _paymentLoadingText = null;
          });
          _showScheduledDialog(result.message);
        }
        return;
      }

      // ── Case 2: Immediate checkout ──────────────────────────────────────
      final upgradeModel = result.order!;
      AppLogger.i(
        '[Upgrade] Upgrade response received — opening Razorpay:\n'
        '  subscriptionId : ${upgradeModel.subscriptionId}\n'
        '  order_id       : ${upgradeModel.order.id}\n'
        '  amount (paise) : ${upgradeModel.order.amount}\n'
        '  currency       : ${upgradeModel.order.currency}\n'
        '  plan           : ${upgradeModel.plan.name}',
      );

      // Store subscriptionId — this is the ONLY field needed for verify-payment
      _activeUpgradeSubscriptionId = upgradeModel.subscriptionId;

      final storage = locator<LocalStorageService>();
      final userName  = storage.getUserName()  ?? 'User';
      final userEmail = storage.getUserEmail() ?? 'info@sevacare.com';
      final userPhone = storage.getUserPhone() ?? '9876543210';

      final options = <String, dynamic>{
        'key':         Env.razorpayKey,
        'amount':      upgradeModel.order.amount,
        'currency':    upgradeModel.order.currency,
        'name':        'Seva Care',
        'description': upgradeModel.plan.name,
        'order_id':    upgradeModel.order.id,
        'prefill': {
          'name':    userName,
          'email':   userEmail,
          'contact': userPhone,
        },
        'theme': {
          'color': '#3F51B5',
        },
      };

      AppLogger.i('[Razorpay] Opening checkout — order_id: ${upgradeModel.order.id}, amount: ${upgradeModel.order.amount}');
      _razorpay.open(options);

    } catch (e, st) {
      AppLogger.e('[Upgrade] Flow failed', e, st);
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _showErrorSnackbar(errorMsg.isNotEmpty ? errorMsg : 'Unable to initiate upgrade. Please try again.');
      if (mounted) {
        setState(() {
          _paymentLoading = false;
          _paymentLoadingText = null;
          _activeUpgradeSubscriptionId = null;
        });
      }
    }
  }

  /// Shows an informational dialog for scheduled plan changes (e.g. downgrade).
  void _showScheduledDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.schedule, color: SevaColors.primary, size: 28),
            const SizedBox(width: 8),
            Text('Plan Change Scheduled', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the cancellation confirmation dialog.
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: SevaColors.textPrimary)),
        content: Text(
          'Are you sure you want to cancel your subscription? Your access will remain active until the current billing cycle ends.',
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelSubscription();
            },
            child: Text('Cancel Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.red)),
          ),
        ],
      ),
    );
  }

  /// Calls the repository to cancel the active subscription and handles loading, success, and error states.
  Future<void> _cancelSubscription() async {
    if (_cancelLoading) return;
    setState(() {
      _cancelLoading = true;
    });

    try {
      final message = await locator<SubscriptionRepository>().cancelSubscription();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: SevaColors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
      // Refresh current subscription API immediately
      await _fetchSubscriptionData();
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.startsWith('Exception: ')) {
        errMsg = errMsg.replaceFirst('Exception: ', '');
      }
      _showErrorSnackbar(errMsg.isNotEmpty ? errMsg : 'Something went wrong');
    } finally {
      if (mounted) {
        setState(() {
          _cancelLoading = false;
        });
      }
    }
  }

  /// Shows the refund confirmation dialog.
  void _showRefundDialog(BuildContext context, PaymentHistoryModel payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Request Refund', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: SevaColors.textPrimary)),
        content: Text(
          'Are you sure you want to request a refund for this payment? This action may not be reversible.',
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _refundPayment(payment.id);
            },
            child: Text('Request Refund', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Calls the repository to request a refund for a payment and handles loading, success, and error states.
  Future<void> _refundPayment(String paymentId) async {
    if (_refundLoading) return;
    setState(() {
      _refundLoading = true;
    });

    try {
      final success = await locator<SubscriptionRepository>().refundPayment(paymentId);
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment refunded successfully'),
                backgroundColor: SevaColors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        // Refresh payment history and subscription information immediately
        await _fetchSubscriptionData();
      }
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.startsWith('Exception: ')) {
        errMsg = errMsg.replaceFirst('Exception: ', '');
      }
      _showErrorSnackbar(errMsg.isNotEmpty ? errMsg : 'Something went wrong');
    } finally {
      if (mounted) {
        setState(() {
          _refundLoading = false;
        });
      }
    }
  }

  /// Shows the cancel payment confirmation dialog.
  void _showCancelPaymentDialog(BuildContext context, PaymentHistoryModel payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: SevaColors.textPrimary)),
        content: Text(
          'Are you sure you want to cancel this pending payment?',
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelPayment(payment.id);
            },
            child: Text('Cancel Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.red)),
          ),
        ],
      ),
    );
  }

  /// Calls the repository to cancel a pending payment and handles loading, success, and error states.
  Future<void> _cancelPayment(String paymentId) async {
    if (_cancelPaymentLoading) return;
    setState(() {
      _cancelPaymentLoading = true;
    });

    try {
      final success = await locator<SubscriptionRepository>().cancelPayment(paymentId);
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment cancelled successfully'),
                backgroundColor: SevaColors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        // Refresh payment history and subscription information immediately
        await _fetchSubscriptionData();
      }
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.startsWith('Exception: ')) {
        errMsg = errMsg.replaceFirst('Exception: ', '');
      }
      _showErrorSnackbar(errMsg.isNotEmpty ? errMsg : 'Something went wrong');
    } finally {
      if (mounted) {
        setState(() {
          _cancelPaymentLoading = false;
        });
      }
    }
  }

  /// Fetches the HTML receipt from the repository and opens the dedicated ReceiptScreen.
  Future<void> _fetchAndOpenReceipt(BuildContext context, PaymentHistoryModel payment) async {
    if (_paymentLoading) return;
    setState(() {
      _paymentLoading = true;
      _paymentLoadingText = 'Fetching receipt...';
    });

    try {
      final html = await locator<SubscriptionRepository>().getPaymentReceipt(payment.id);
      if (html == null || html.isEmpty) {
        throw Exception('Receipt data is empty or missing');
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              paymentId: payment.id,
              htmlContent: html,
              planName: payment.planName,
              status: payment.status,
              amount: payment.amount,
              currency: payment.currency,
              date: payment.createdAt,
            ),
          ),
        );
      }
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.startsWith('Exception: ')) {
        errMsg = errMsg.replaceFirst('Exception: ', '');
      }
      _showErrorSnackbar(errMsg.isNotEmpty ? errMsg : 'Failed to load receipt');
    } finally {
      if (mounted) {
        setState(() {
          _paymentLoading = false;
          _paymentLoadingText = null;
        });
      }
    }
  }
}

