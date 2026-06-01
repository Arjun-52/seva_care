import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../../core/api/api_client.dart';
import '../../services/dependency_injection.dart';
import '../../utils/app_logger.dart';
import '../../models/current_subscription_model.dart';
import '../../models/upgrade_subscription_model.dart';
import 'family_payment_screen.dart';
import '../../models/payment_history_model.dart';
import '../../repositories/subscription_repository.dart';
import '../../core/errors/failure.dart';




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


  @override
  void initState() {
    super.initState();
    _fetchSubscriptionData();
  }

  @override
  void dispose() {
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
    return Scaffold(
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
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: SevaColors.sevaGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SevaColors.primary.withAlpha(51),
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
                color: isActive ? SevaColors.green.withAlpha(51) : SevaColors.red.withAlpha(51),
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
          'Active: ${_formatDate(sub.startDate)} | Renews: ${_formatDate(sub.endDate)}',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Text(formattedPrice, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(formattedPeriod, style: GoogleFonts.inter(fontSize: 14, color: Colors.white60)),
        ]),
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
                          gradient: isPopular ? SevaColors.sevaGradient : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _showUpgradeDialog(context, plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPopular ? Colors.transparent : SevaColors.primary,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Upgrade to ${plan.name}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
    const months = ['Jun', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    // Let's safe guard the month name mapping
    final monthName = date.month >= 1 && date.month <= 12 ? months[date.month - 1] : 'Jun';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isSuccess ? SevaColors.greenLight : SevaColors.orangeLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.pending,
              size: 18,
              color: isSuccess ? SevaColors.green : SevaColors.orange,
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
    );
  }

  void _showUpgradeDialog(BuildContext context, SubscriptionPlan plan) {
    bool upgrading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Upgrade to ${plan.name}?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You will be charged ${plan.price}${plan.period} starting from your next billing cycle.',
                style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: SevaColors.greenLight, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: SevaColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can cancel anytime. Prorated refund available.',
                        style: GoogleFonts.inter(fontSize: 12, color: SevaColors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: upgrading ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: SevaColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: upgrading
                  ? null
                  : () async {
                      dialogSetState(() => upgrading = true);
                      AppLogger.i('Upgrade subscription started');
                      AppLogger.i('Selected plan ID: ${plan.id}');

                      try {
                        final res = await locator<ApiClient>().post(
                          'subscriptions/upgrade',
                          body: {'planId': plan.id},
                        );

                        if (res.success && res.data != null) {
                          AppLogger.i('Upgrade API success');
                          final upgradeModel = UpgradeSubscriptionModel.fromJson(
                            res.data as Map<String, dynamic>,
                          );
                          AppLogger.i('Subscription ID received: ${upgradeModel.subscriptionId}');
                          AppLogger.i('Payment ID received: ${upgradeModel.paymentId}');
                          AppLogger.i('Order ID received: ${upgradeModel.order.id}');

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          AppLogger.i('Navigation to payment screen');
                          if (context.mounted) {
                            final paymentSuccess = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FamilyPaymentScreen(
                                  orderId: upgradeModel.order.id,
                                  amount: upgradeModel.order.amount,
                                  currency: upgradeModel.order.currency,
                                  subscriptionId: upgradeModel.subscriptionId,
                                  paymentId: upgradeModel.paymentId,
                                  planName: plan.name,
                                ),
                              ),
                            );

                            if (paymentSuccess == true) {
                              _fetchSubscriptionData();
                            }
                          }
                        } else {
                          AppLogger.e('API failure: ${res.errorMessage}');
                          String displayError = res.errorMessage;
                          _showErrorSnackbar(displayError);
                          dialogSetState(() => upgrading = false);
                        }
                      } catch (e, stack) {
                        AppLogger.e('API failure', e, stack);
                        String displayError = 'Unable to initiate subscription. Please try again.';
                        if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
                          displayError = 'Unable to connect. Please check your internet connection.';
                        }
                        _showErrorSnackbar(displayError);
                        dialogSetState(() => upgrading = false);
                      }
                    },
              child: upgrading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirm Upgrade'),
            ),
          ],
        ),
      ),
    );
  }
}
