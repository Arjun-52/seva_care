import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../utils/app_logger.dart';
import '../../models/subscription_list_model.dart';
import '../../repositories/subscription_repository.dart';
import '../../services/dependency_injection.dart';
import 'receipt_screen.dart';

class FamilySubscriptionsListScreen extends StatefulWidget {
  const FamilySubscriptionsListScreen({super.key});

  @override
  State<FamilySubscriptionsListScreen> createState() => _FamilySubscriptionsListScreenState();
}

class _FamilySubscriptionsListScreenState extends State<FamilySubscriptionsListScreen> {
  bool _loading = false;
  List<SubscriptionModel> _subscriptions = [];
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await locator<SubscriptionRepository>().getSubscriptions();
      if (mounted) {
        setState(() {
          _subscriptions = list;
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to fetch subscriptions: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SevaColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SevaColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildSubscriptionStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = SevaColors.greenLight;
        textColor = SevaColors.green;
        label = 'Active';
        break;
      case 'cancelled':
        bgColor = SevaColors.redLight;
        textColor = SevaColors.red;
        label = 'Cancelled';
        break;
      case 'pending_payment':
        bgColor = SevaColors.orangeLight;
        textColor = SevaColors.orange;
        label = 'Pending Payment';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = status.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String? status) {
    if (status == null) return const SizedBox.shrink();
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = SevaColors.greenLight;
        textColor = SevaColors.green;
        label = 'Completed';
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
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = status.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        'Payment: $label',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Future<void> _fetchAndOpenReceipt(SubscriptionModel sub) async {
    final paymentId = sub.paymentId;
    if (paymentId == null || paymentId.isEmpty) return;

    setState(() => _actionLoading = true);
    try {
      final html = await locator<SubscriptionRepository>().getPaymentReceipt(paymentId);
      if (html == null || html.isEmpty) {
        throw Exception('Receipt template not found');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              paymentId: paymentId,
              htmlContent: html,
              planName: sub.plan,
              status: sub.paymentStatus ?? 'completed',
              amount: sub.amount,
              currency: 'INR',
              date: sub.since ?? DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  void _showCancelSubscriptionDialog(SubscriptionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: SevaColors.textPrimary)),
        content: Text(
          'Are you sure you want to cancel your subscription for "${sub.plan}"? Access will remain active until the end of the billing period.',
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
              _cancelSubscription(sub);
            },
            child: Text('Cancel Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription(SubscriptionModel sub) async {
    setState(() => _actionLoading = true);
    try {
      final message = await locator<SubscriptionRepository>().cancelSubscription();
      _showSuccessSnackbar(message);
      await _fetchSubscriptions();
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _toggleAutoRenew(SubscriptionModel sub, bool newValue) async {
    setState(() => _actionLoading = true);
    try {
      await locator<SubscriptionRepository>().updateSubscription(
        subscriptionId: sub.id,
        data: {'autoRenew': newValue},
      );
      _showSuccessSnackbar('Auto-renew settings updated!');
      await _fetchSubscriptions();
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  /// Shows the delete confirmation dialog.
  void _showDeleteSubscriptionDialog(SubscriptionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: SevaColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete this subscription? This action is irreversible and will remove all history associated with it.',
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
              _deleteSubscription(sub);
            },
            child: Text('Delete Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.red)),
          ),
        ],
      ),
    );
  }

  /// Calls the repository to delete a subscription and handles loading, success, and error states.
  Future<void> _deleteSubscription(SubscriptionModel sub) async {
    setState(() => _actionLoading = true);
    try {
      final message = await locator<SubscriptionRepository>().deleteSubscription(subscriptionId: sub.id);
      _showSuccessSnackbar(message);
      await _fetchSubscriptions();
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        actions: [
          if (_actionLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: SevaColors.primary))),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSubscriptions,
        color: SevaColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _subscriptions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: SevaColors.primary));
    }

    if (_error != null && _subscriptions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: SevaColors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: SevaColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchSubscriptions, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 54, color: SevaColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'No subscriptions history available',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Explore plans to enroll and monitor seniors.',
                style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final sub = _subscriptions[index];
        final isActive = sub.status.toLowerCase() == 'active';
        final isCancelled = sub.status.toLowerCase() == 'cancelled';
        final isCompleted = sub.paymentStatus?.toLowerCase() == 'completed';
        final isPendingPayment = sub.paymentStatus?.toLowerCase() == 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sub.plan,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: SevaColors.textPrimary),
                      ),
                    ),
                    _buildSubscriptionStatusBadge(sub.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${sub.amount}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: SevaColors.primary),
                    ),
                    const SizedBox(width: 12),
                    _buildPaymentStatusBadge(sub.paymentStatus),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: SevaColors.divider, height: 1),
                const SizedBox(height: 16),

                // Subscription Info Grid
                _buildInfoRow(Icons.person_outline, 'NRI Sponsor', sub.nriName),
                _buildInfoRow(Icons.public, 'Country', sub.country),
                _buildInfoRow(Icons.elderly_outlined, 'Assigned Senior', sub.senior),
                _buildInfoRow(Icons.calendar_today_outlined, 'Start Date', _formatDate(sub.since)),
                _buildInfoRow(Icons.schedule, 'Next Billing', _formatDate(sub.nextBilling)),
                if (isActive) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.autorenew, size: 16, color: SevaColors.textTertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Auto Renew Plan',
                                style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary),
                              ),
                              SizedBox(
                                height: 24,
                                child: Switch.adaptive(
                                  value: sub.autoRenew,
                                  onChanged: _actionLoading ? null : (val) => _toggleAutoRenew(sub, val),
                                  activeTrackColor: SevaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Actions Section
                if (sub.paymentId != null || isActive || isCancelled) ...[
                  const SizedBox(height: 16),
                  const Divider(color: SevaColors.divider, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // View Receipt Button
                      if (isCompleted && sub.paymentId != null) ...[
                        OutlinedButton.icon(
                          onPressed: _actionLoading ? null : () => _fetchAndOpenReceipt(sub),
                          icon: const Icon(Icons.receipt_outlined, size: 14),
                          label: const Text('View Receipt'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SevaColors.primary,
                            side: const BorderSide(color: SevaColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Continue Payment Button
                      if (isPendingPayment) ...[
                        ElevatedButton.icon(
                          onPressed: _actionLoading ? null : () => _showSuccessSnackbar('Payment continued. Loading checkout...'),
                          icon: const Icon(Icons.payment, size: 14),
                          label: const Text('Continue Payment'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Cancel Subscription Button
                      if (isActive) ...[
                        OutlinedButton.icon(
                          onPressed: _actionLoading ? null : () => _showCancelSubscriptionDialog(sub),
                          icon: const Icon(Icons.cancel_outlined, size: 14),
                          label: const Text('Cancel Plan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SevaColors.red,
                            side: const BorderSide(color: SevaColors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Cancelled Label
                      if (isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: SevaColors.redLight, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: SevaColors.red),
                              const SizedBox(width: 6),
                              Text(
                                'Cancelled Plan',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: SevaColors.red),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Delete Button
                      IconButton(
                        onPressed: _actionLoading ? null : () => _showDeleteSubscriptionDialog(sub),
                        icon: const Icon(Icons.delete_outline, color: SevaColors.red, size: 20),
                        tooltip: 'Delete Subscription',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: SevaColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
