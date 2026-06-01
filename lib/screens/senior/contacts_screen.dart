import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('My Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Quick dial - SOS
          GestureDetector(
            onTap: () => _showCallDialog(context, 'Seva Emergency Helpline', '1800-XXX-XXXX'),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: SevaColors.red.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.emergency, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Emergency Helpline', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('1800-XXX-XXXX (Toll Free)', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                ])),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.phone, color: Colors.white, size: 24),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          Text('My People', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Tap to call', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
          const SizedBox(height: 16),

          ...MockData.emergencyContacts.map((contact) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _showCallDialog(context, contact.name, contact.phone),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: contact.isPrimary ? SevaColors.primary.withValues(alpha: 0.3) : SevaColors.border,
                    width: contact.isPrimary ? 2 : 1),
                ),
                child: Row(children: [
                  SevaAvatar(
                    initials: contact.avatar, size: 56,
                    bgColor: contact.isPrimary ? SevaColors.primary : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(contact.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (contact.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                          child: Text('Primary', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: SevaColors.primary)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(contact.relation, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(contact.phone, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textTertiary)),
                  ])),
                  Column(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: SevaColors.greenLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.phone, color: SevaColors.green, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.videocam, color: SevaColors.primary, size: 22),
                    ),
                  ]),
                ]),
              ),
            ),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showCallDialog(BuildContext context, String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: SevaColors.greenLight, shape: BoxShape.circle),
            child: const Icon(Icons.phone_in_talk, color: SevaColors.green, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Call $name?', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(phone, style: GoogleFonts.inter(fontSize: 15, color: SevaColors.textSecondary)),
        ]),
        actions: [
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Cancel'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Calling $name...'),
                  behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: SevaColors.green,
                padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Call'),
            )),
          ]),
        ],
      ),
    );
  }
}
