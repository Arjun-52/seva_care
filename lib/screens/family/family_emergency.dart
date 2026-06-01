import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class FamilyEmergency extends StatelessWidget {
  const FamilyEmergency({super.key});

  @override
  Widget build(BuildContext context) {
    final activeAlerts = MockData.emergencyAlerts.where((a) => a.status != 'resolved').toList();
    final resolved = MockData.emergencyAlerts.where((a) => a.status == 'resolved').toList();

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: Text(t('emergency'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // SOS Button
          GestureDetector(
            onTap: () => _showSOSDialog(context),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: SevaColors.red.withAlpha(76), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.emergency, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t('trigger_sos'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(t('sos_confirm'),
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // Active Alerts
          if (activeAlerts.isNotEmpty) ...[
            SectionTitle(title: '${t('active_alerts')} (${activeAlerts.length})', icon: Icons.warning_amber),
            const SizedBox(height: 12),
            ...activeAlerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: alert.severity == 'critical' ? SevaColors.redLight : SevaColors.amberLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: alert.severity == 'critical'
                    ? SevaColors.red.withAlpha(76) : SevaColors.amber.withAlpha(76)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: alert.severity == 'critical' ? SevaColors.red.withAlpha(38) : SevaColors.amber.withAlpha(38),
                        borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.warning, size: 22,
                        color: alert.severity == 'critical' ? SevaColors.red : SevaColors.amber),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(alert.type, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                        color: alert.severity == 'critical' ? SevaColors.red : SevaColors.amber)),
                      Text(alert.seniorName, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: alert.severity == 'critical' ? SevaColors.red.withAlpha(38) : SevaColors.amber.withAlpha(38),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(alert.severity == 'critical' ? t('critical').toUpperCase() : t('elevated').toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                          color: alert.severity == 'critical' ? SevaColors.red : SevaColors.amber)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: SevaColors.textTertiary),
                    const SizedBox(width: 4),
                    Text('${alert.zone}, ${alert.city}', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.person_outline, size: 14, color: SevaColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(alert.responder, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                  ]),
                  if (alert.eta != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.timer, size: 14, color: SevaColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('ETA: ${alert.eta}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text(t('responding')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alert.severity == 'critical' ? SevaColors.red : SevaColors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Resolved
          if (resolved.isNotEmpty) ...[
            SectionTitle(title: '${t('resolved')} (${resolved.length})', icon: Icons.check_circle_outline),
            const SizedBox(height: 12),
            ...resolved.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SevaCard(child: Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: SevaColors.greenLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_circle, size: 18, color: SevaColors.green)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${a.type} — ${a.seniorName}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('${a.zone} · ${t('resolved')} — ${a.responder}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                ])),
                const StatusBadge(status: 'completed'),
              ])),
            )),
          ],
        ]),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.emergency, color: SevaColors.red, size: 28),
        const SizedBox(width: 10),
        Text('${t('trigger_sos')}?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ]),
      content: Text(t('sos_confirm'),
        style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red),
          child: Text(t('trigger_sos')),
        ),
      ],
    ));
  }
}
