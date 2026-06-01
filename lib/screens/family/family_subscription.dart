import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class FamilySubscription extends StatelessWidget {
  const FamilySubscription({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Current plan summary
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: SevaColors.sevaGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('CURRENT PLAN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                ),
              ]),
              const SizedBox(height: 12),
              Text('Basic Connect', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Active since Jan 2025 | Renews Jun 15, 2025',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 12),
              Row(children: [
                Text('₹2,999', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(' /month', style: GoogleFonts.inter(fontSize: 14, color: Colors.white60)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          Text('Choose Your Plan', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Upgrade anytime. Cancel anytime.', style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
          const SizedBox(height: 20),

          // Plans
          ...MockData.subscriptionPlans.map((plan) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: plan.isPopular ? SevaColors.primary : plan.isCurrent ? SevaColors.green : SevaColors.border,
                  width: plan.isPopular || plan.isCurrent ? 2 : 1,
                ),
                boxShadow: plan.isPopular ? [BoxShadow(color: SevaColors.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))] : null,
              ),
              child: Column(children: [
                // Header badge
                if (plan.isPopular || plan.isCurrent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: plan.isPopular ? SevaColors.primary : SevaColors.green,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                    ),
                    child: Center(child: Text(
                      plan.isCurrent ? 'CURRENT PLAN' : 'MOST POPULAR',
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
                            color: plan.isPopular ? SevaColors.primaryLight : SevaColors.greenLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, size: 12,
                            color: plan.isPopular ? SevaColors.primary : SevaColors.green),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textPrimary, height: 1.3))),
                      ]),
                    )),
                    const SizedBox(height: 16),

                    // CTA Button
                    SizedBox(width: double.infinity, child: plan.isCurrent
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
                            gradient: plan.isPopular ? SevaColors.sevaGradient : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () => _showUpgradeDialog(context, plan),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: plan.isPopular ? Colors.transparent : SevaColors.primary,
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
          )),

          // Payment history
          const SizedBox(height: 8),
          const SectionTitle(title: 'Payment History', icon: Icons.receipt_long),
          const SizedBox(height: 12),
          SevaCard(padding: EdgeInsets.zero, child: Column(children: [
            _paymentRow('May 2025', '₹2,999', 'Paid', SevaColors.green),
            const Divider(height: 1, color: SevaColors.divider, indent: 16),
            _paymentRow('Apr 2025', '₹2,999', 'Paid', SevaColors.green),
            const Divider(height: 1, color: SevaColors.divider, indent: 16),
            _paymentRow('Mar 2025', '₹2,999', 'Paid', SevaColors.green),
            const Divider(height: 1, color: SevaColors.divider, indent: 16),
            _paymentRow('Feb 2025', '₹2,999', 'Paid', SevaColors.green),
            const Divider(height: 1, color: SevaColors.divider, indent: 16),
            _paymentRow('Jan 2025', '₹2,999', 'Paid', SevaColors.green),
          ])),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _paymentRow(String month, String amount, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: SevaColors.greenLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.check_circle, size: 18, color: SevaColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(month, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          Text('Basic Connect', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
        ])),
        Text(amount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  void _showUpgradeDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Upgrade to ${plan.name}?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('You will be charged ${plan.price}${plan.period} starting from your next billing cycle.',
            style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: SevaColors.greenLight, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 16, color: SevaColors.green),
              const SizedBox(width: 8),
              Expanded(child: Text('You can cancel anytime. Prorated refund available.',
                style: GoogleFonts.inter(fontSize: 12, color: SevaColors.green))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: SevaColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Upgraded to ${plan.name}! Changes will reflect in your next billing cycle.'),
                behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
              ));
            },
            child: const Text('Confirm Upgrade'),
          ),
        ],
      ),
    );
  }
}
