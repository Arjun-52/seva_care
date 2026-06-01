import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/help_support_screen.dart';
import 'family_documents.dart';
import 'family_subscription.dart';

class FamilyProfile extends StatelessWidget {
  const FamilyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: Text(t('profile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Profile Header
          SevaCard(child: Column(children: [
            const SevaAvatar(initials: 'RS', size: 72, bgColor: SevaColors.primary),
            const SizedBox(height: 12),
            Text('Rajesh Sharma', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
            const SizedBox(height: 4),
            Text('New Jersey, USA', style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text('${t('family')} Account', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.primary)),
            ),
          ])),
          const SizedBox(height: 16),

          // Subscription
          SevaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.credit_card, color: SevaColors.primary, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('current_plan'), style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                Text(t('basic_connect'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹2,999', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
                Text(t('per_month'), style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
              ]),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: SevaColors.primaryLight.withAlpha(127), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 16, color: SevaColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('${t('upgrade')} to ${t('care_plus')}',
                  style: GoogleFonts.inter(fontSize: 12, color: SevaColors.primary))),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilySubscription())),
                child: Text(t('upgrade')),
              )),
          ])),
          const SizedBox(height: 16),

          // Settings List
          SevaCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _settingsItem(Icons.folder_outlined, t('document_vault'), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyDocuments()));
              }),
              _divider(),
              _settingsItem(Icons.payment, t('subscription'), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilySubscription()));
              }),
              _divider(),
              _settingsItem(Icons.notifications_outlined, t('notification_settings'), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
              _divider(),
              _settingsItem(Icons.language, t('language'), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }, trailing: SevaLocalizations.currentLanguage.nativeName),
              _divider(),
              _settingsItem(Icons.help_outline, t('help_support'), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
              }),
              _divider(),
              _settingsItem(Icons.privacy_tip_outlined, t('privacy_security'), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
            ]),
          ),
          const SizedBox(height: 16),

          // Sign Out
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSignOutDialog(context),
              icon: const Icon(Icons.logout, color: SevaColors.red),
              label: Text(t('sign_out'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: SevaColors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('${t('app_name')} v1.0.0', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _settingsItem(IconData icon, String label, VoidCallback onTap, {String? trailing}) {
    return InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 22, color: SevaColors.textSecondary),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: SevaColors.textPrimary))),
        if (trailing != null)
          Text(trailing, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textTertiary)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 20, color: SevaColors.textTertiary),
      ]),
    ));
  }

  Widget _divider() => const Divider(height: 1, color: SevaColors.divider, indent: 52);

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${t('sign_out')}?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(t('sign_out_confirm'),
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red),
            child: Text(t('sign_out')),
          ),
        ],
      ),
    );
  }
}
