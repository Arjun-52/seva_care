import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../../repositories/notification_repository.dart';
import '../shared/senior_detail_screen.dart';
import 'family_notifications.dart';
import 'family_seniors.dart';

class FamilyDashboard extends StatelessWidget {
  const FamilyDashboard({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return t('good_morning');
    if (hour < 17) return t('good_afternoon');
    return t('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    final senior = MockData.seniors[0];
    final logs = MockData.careLogs.where((l) => l.seniorId == "SR001").toList();
    final completed = logs.where((l) => l.status == "completed").length;

    return Scaffold(
      backgroundColor: SevaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_greeting()}, Rajesh', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
                const SizedBox(height: 4),
                Text(t('heres_update'), style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
              ])),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyNotifications())),
                child: ValueListenableBuilder<int>(
                  valueListenable: NotificationRepository.unreadCountNotifier,
                  builder: (context, count, child) {
                    return Stack(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SevaColors.border)),
                        child: const Icon(Icons.notifications_outlined, color: SevaColors.textSecondary),
                      ),
                      if (count > 0)
                        Positioned(right: 0, top: 0, child: Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(color: SevaColors.red, shape: BoxShape.circle),
                          child: Center(child: Text('$count', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                        )),
                    ]);
                  }
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Senior Profile Card
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: senior))),
              child: GradientHeader(child: Column(children: [
                Row(children: [
                  const SevaAvatar(initials: 'KD', size: 56, bgColor: Colors.white24),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(senior.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text('${senior.zone}, ${senior.city}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                      const SizedBox(width: 12),
                      Text('${t('age')} ${senior.age}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                    ]),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(t('stable'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text('${t('care_aide')}: ${senior.careAide}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
                ]),
              ])),
            ),
            const SizedBox(height: 16),

            // Vitals Grid
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
              children: [
                VitalCard(label: t('blood_pressure'), value: senior.vitals['bp'], subtitle: 'mmHg — ${t('normal')}',
                  icon: Icons.monitor_heart, color: const Color(0xFF1E40AF), bgColor: SevaColors.primaryLight),
                VitalCard(label: t('oxygen_level'), value: '${senior.vitals['spo2']}%', subtitle: '${t('oxygen_level')} — ${t('normal')}',
                  icon: Icons.favorite, color: const Color(0xFF047857), bgColor: SevaColors.greenLight),
                VitalCard(label: t('heart_rate'), value: '${senior.vitals['heartRate']} bpm', subtitle: '${t('normal')}',
                  icon: Icons.trending_up, color: const Color(0xFF6D28D9), bgColor: SevaColors.purpleLight),
                VitalCard(label: t('temperature'), value: '${senior.vitals['temp']}°F', subtitle: '${t('normal')}',
                  icon: Icons.thermostat, color: const Color(0xFFC2410C), bgColor: SevaColors.orangeLight),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            SectionTitle(title: t('quick_actions'), icon: Icons.flash_on),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              QuickActionButton(icon: Icons.phone, label: t('call_aide'), color: SevaColors.green, bgColor: SevaColors.greenLight,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Calling Priya Meena...'), behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                  ));
                }),
              QuickActionButton(icon: Icons.emergency, label: t('sos'), color: SevaColors.red, bgColor: SevaColors.redLight,
                onTap: () => _showSOSConfirm(context)),
              QuickActionButton(icon: Icons.videocam, label: t('video_call'), color: SevaColors.primary, bgColor: SevaColors.primaryLight,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Starting video call with Kamla Ji...'), behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                  ));
                }),
              QuickActionButton(icon: Icons.medication, label: t('medicines'), color: SevaColors.purple, bgColor: SevaColors.purpleLight,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${MockData.medicines.where((m) => !m.taken).length} ${t('medicines')} ${t('pending')}'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }),
              QuickActionButton(icon: Icons.people, label: t('all_seniors'), color: SevaColors.orange, bgColor: SevaColors.orangeLight,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilySeniors()))),
            ]),
            const SizedBox(height: 24),

            // Care Timeline
            SectionTitle(title: t('todays_care'), icon: Icons.schedule,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: SevaColors.greenLight, borderRadius: BorderRadius.circular(20)),
                child: Text('$completed/${logs.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.green)),
              ),
            ),
            const SizedBox(height: 12),
            SevaCard(
              padding: const EdgeInsets.all(0),
              child: ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: SevaColors.divider),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: log.status == 'completed' ? SevaColors.greenLight
                              : log.status == 'active' ? SevaColors.primaryLight : SevaColors.divider,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          log.status == 'completed' ? Icons.check_circle : log.status == 'active' ? Icons.play_circle_outline : Icons.schedule,
                          size: 18,
                          color: log.status == 'completed' ? SevaColors.green
                              : log.status == 'active' ? SevaColors.primary : SevaColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(log.activity,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                            color: log.status == 'pending' ? SevaColors.textTertiary : SevaColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('${log.time} · ${log.who}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      ])),
                      StatusBadge(status: log.status),
                    ]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Health Conditions
            SectionTitle(title: t('conditions'), icon: Icons.medical_information),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: senior.conditions.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: SevaColors.redLight, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.favorite, size: 14, color: SevaColors.red),
                const SizedBox(width: 6),
                Text(c, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: SevaColors.red)),
              ]),
            )).toList()),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  void _showSOSConfirm(BuildContext context) {
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
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(t('sos_triggered')),
              ]),
              behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.red,
              duration: const Duration(seconds: 4),
            ));
          },
          style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red),
          child: Text(t('trigger_sos')),
        ),
      ],
    ));
  }
}
