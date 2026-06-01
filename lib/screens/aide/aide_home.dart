import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../auth/login_screen.dart';
import '../shared/senior_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/help_support_screen.dart';
import 'record_vitals_screen.dart';
import 'visit_summary_screen.dart';

class AideHome extends StatefulWidget {
  const AideHome({super.key});

  @override
  State<AideHome> createState() => _AideHomeState();
}

class _AideHomeState extends State<AideHome> {
  int _tab = 0;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return t('good_morning');
    if (hour < 17) return t('good_afternoon');
    return t('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      body: SafeArea(child: _tab == 0 ? _tasksView() : _tab == 1 ? _seniorsView() : _profileView()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, -4))]),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _navItem(Icons.checklist, t('my_tasks'), 0),
            _navItem(Icons.people, t('my_seniors'), 1),
            _navItem(Icons.person, t('profile'), 2),
          ]),
        )),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: active ? SevaColors.primaryLight : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? SevaColors.primary : SevaColors.textTertiary, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? SevaColors.primary : SevaColors.textTertiary)),
        ]),
      ),
    );
  }

  Widget _tasksView() {
    final tasks = MockData.careLogs;
    final done = tasks.where((t) => t.status == 'completed').length;
    final total = tasks.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_greeting()}, Priya', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
            Text('${total - done} ${t('pending')} ${t('today').toLowerCase()}', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
          ])),
          CircularPercentIndicator(
            radius: 30, lineWidth: 5, percent: done / total,
            center: Text('$done/$total', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
            progressColor: SevaColors.green, backgroundColor: SevaColors.greenLight,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ]),
        const SizedBox(height: 20),

        // Current Visit
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: MockData.seniors[0]))),
          child: GradientHeader(child: Row(children: [
            const SevaAvatar(initials: 'KD', size: 48, bgColor: Colors.white24),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('current_visit'), style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              Text('Kamla Devi Sharma', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Vaishali Nagar, Jaipur', style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
            ])),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Opening navigation to Vaishali Nagar...'),
                  behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.teal,
                ));
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.navigation, color: Colors.white, size: 22),
              ),
            ),
          ])),
        ),
        const SizedBox(height: 20),

        // Task List
        SectionTitle(title: t('todays_schedule'), icon: Icons.checklist),
        const SizedBox(height: 12),
        ...tasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SevaCard(child: Row(children: [
            GestureDetector(
              onTap: () {
                if (task.status == 'pending') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${t('start_task')}: ${task.activity}'),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                  ));
                } else if (task.status == 'active') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${t('completed')}: ${task.activity}'),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                  ));
                }
              },
              child: Container(width: 36, height: 36,
                decoration: BoxDecoration(
                  color: task.status == 'completed' ? SevaColors.green
                      : task.status == 'active' ? SevaColors.primary : SevaColors.border,
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  task.status == 'completed' ? Icons.check : task.status == 'active' ? Icons.play_arrow : Icons.schedule,
                  color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.activity, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                color: task.status == 'completed' ? SevaColors.textTertiary : SevaColors.textPrimary,
                decoration: task.status == 'completed' ? TextDecoration.lineThrough : null)),
              Text(task.time, style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
            ])),
            if (task.status == 'pending')
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${t('start_task')}: ${task.activity}'),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(t('start_task'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.primary)),
                ),
              ),
          ])),
        )),

        const SizedBox(height: 20),

        // Record Vitals Button
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordVitalsScreen())),
            icon: const Icon(Icons.monitor_heart),
            label: Text(t('record_vitals')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: SevaColors.teal,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Camera opening for photo proof... (demo)'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(t('upload_photo')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [SevaColors.green, SevaColors.teal]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitSummaryScreen())),
              icon: const Icon(Icons.summarize),
              label: Text(t('end_visit')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _seniorsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('my_seniors'), style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
        Text('${MockData.seniors.length} ${t('senior').toLowerCase()}s', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
        const SizedBox(height: 16),
        ...MockData.seniors.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SevaCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: s))),
            child: Row(children: [
              SevaAvatar(initials: s.avatar, size: 44),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 13, color: SevaColors.textTertiary),
                  const SizedBox(width: 3),
                  Text('${s.zone}, ${s.city}', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _miniVital('BP', s.vitals['bp'], SevaColors.primary),
                  const SizedBox(width: 8),
                  _miniVital('SpO2', '${s.vitals['spo2']}%', SevaColors.green),
                  const SizedBox(width: 8),
                  _miniVital('HR', '${s.vitals['heartRate']}', SevaColors.purple),
                ]),
              ])),
              StatusBadge(status: s.status),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _miniVital(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(4)),
      child: Text('$label $value', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _profileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(gradient: SevaColors.sevaGradient, borderRadius: BorderRadius.circular(40)),
          child: const Center(child: Text('PM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        const SizedBox(height: 14),
        Text('Priya Meena', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
        Text('${t('care_aide')} · Vaishali Nagar, Jaipur', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star, color: SevaColors.amber, size: 18),
          const SizedBox(width: 4),
          Text('4.8', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Text('${MockData.seniors.length} ${t('senior').toLowerCase()}s', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
        ]),
        const SizedBox(height: 24),

        // Stats cards
        Row(children: [
          _statCard(t('completed'), '156', SevaColors.green, SevaColors.greenLight),
          const SizedBox(width: 10),
          _statCard(t('my_tasks'), '42', SevaColors.primary, SevaColors.primaryLight),
          const SizedBox(width: 10),
          _statCard('Rating', '4.8', SevaColors.amber, SevaColors.amberLight),
        ]),
        const SizedBox(height: 20),

        SevaCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _profileItem(Icons.badge_outlined, 'ID: CT001', null),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _profileItem(Icons.phone_outlined, '+91 94XXX XXXXX', null),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _profileItem(Icons.calendar_today, 'Joined: Jan 2025', null),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _profileItem(Icons.verified, 'Police Verified', null),
          ]),
        ),
        const SizedBox(height: 16),

        SevaCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _profileNav(Icons.settings, t('settings'), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _profileNav(Icons.help_outline, t('help_support'), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            }),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _profileNav(Icons.description, t('training'), () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Opening training materials...'),
                behavior: SnackBarBehavior.floating,
              ));
            }),
          ]),
        ),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showSignOut(),
            icon: const Icon(Icons.logout, color: SevaColors.red),
            label: Text(t('sign_out'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: SevaColors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 12),
        Text('${t('app_name')} v1.0.0', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _statCard(String label, String value, Color color, Color bg) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    ));
  }

  Widget _profileItem(IconData icon, String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: SevaColors.textSecondary),
          const SizedBox(width: 14),
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _profileNav(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: SevaColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textPrimary))),
          const Icon(Icons.chevron_right, size: 20, color: SevaColors.textTertiary),
        ]),
      ),
    );
  }

  void _showSignOut() {
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
