import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Contact card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: SevaColors.sevaGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Need Help?', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Our support team is available 24/7', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _contactButton(context, Icons.phone, 'Call Us', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Calling support: 1800-XXX-XXXX'),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                  ));
                })),
                const SizedBox(width: 12),
                Expanded(child: _contactButton(context, Icons.chat, 'Chat', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Starting chat with support...'),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                  ));
                })),
                const SizedBox(width: 12),
                Expanded(child: _contactButton(context, Icons.email, 'Email', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Opening email: support@seva.org.in'),
                    behavior: SnackBarBehavior.floating,
                  ));
                })),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // FAQ
          Text('Frequently Asked Questions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          _faqItem('How do I upgrade my subscription plan?',
            'Go to Profile > Subscription Plans and choose the plan that best fits your needs. Changes take effect from the next billing cycle. You can also downgrade at any time.'),
          _faqItem('What happens during an emergency SOS?',
            'When SOS is triggered, the nearest care aide is immediately alerted and dispatched. The Seva command center coordinates the response. Emergency services (112) are contacted if needed. Our guaranteed SLA is 30 minutes.'),
          _faqItem('How are vitals monitored?',
            'IoT devices (smartwatch, BP monitor, SpO2 sensor) automatically record vitals at regular intervals. Care aides also take manual readings during visits. All data is available on your dashboard in real-time.'),
          _faqItem('Can I add more than one senior?',
            'Yes! Contact our support team to add additional seniors to your plan. Each senior gets their own dedicated care aide and IoT device kit.'),
          _faqItem('How is my data protected?',
            'All data is encrypted with AES-256 encryption, stored within India, and fully compliant with the DPDP Act 2023. You have full control over your data and can request deletion at any time.'),
          _faqItem('What are the IoT devices included?',
            'Depending on your plan, devices include: GPS smartwatch, blood pressure monitor, SpO2 sensor, gas/smoke detector, door sensor, and a Zigbee hub that connects all devices.'),
          _faqItem('How do I contact my care aide?',
            'You can call or video call your assigned care aide directly from the app. Go to Dashboard > Quick Actions > Call Aide.'),

          const SizedBox(height: 24),

          // Quick links
          Text('Quick Links', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SevaCard(padding: EdgeInsets.zero, child: Column(children: [
            _linkItem(Icons.play_circle, 'Getting Started Guide', () {}),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _linkItem(Icons.video_library, 'Video Tutorials', () {}),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _linkItem(Icons.book, 'User Manual', () {}),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _linkItem(Icons.feedback, 'Send Feedback', () {
              _showFeedbackDialog(context);
            }),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _linkItem(Icons.bug_report, 'Report a Bug', () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Bug report form opening...'),
                behavior: SnackBarBehavior.floating,
              ));
            }),
          ])),
          const SizedBox(height: 24),

          // Office info
          SevaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Seva Senior Care', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _officeRow(Icons.location_on, 'C-11, Vaishali Nagar, Jaipur 302021'),
            _officeRow(Icons.phone, '1800-XXX-XXXX (Toll Free)'),
            _officeRow(Icons.email, 'support@seva.org.in'),
            _officeRow(Icons.language, 'www.seva.org.in'),
            const SizedBox(height: 8),
            Text('CIN: U85100RJ2025NPL012345', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
          ])),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _contactButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: SevaColors.border)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: SevaColors.border)),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        title: Text(question, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
        iconColor: SevaColors.primary,
        collapsedIconColor: SevaColors.textTertiary,
        children: [
          Text(answer, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _linkItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: SevaColors.primary),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, size: 20, color: SevaColors.textTertiary),
        ]),
      ),
    );
  }

  Widget _officeRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: SevaColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary))),
      ]),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Send Feedback', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('We value your feedback. Help us improve Seva.',
            style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Your feedback...',
              alignLabelWithHint: true,
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Thank you for your feedback!'),
                behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
              ));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
