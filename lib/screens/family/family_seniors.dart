import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../shared/senior_detail_screen.dart';

class FamilySeniors extends StatelessWidget {
  const FamilySeniors({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('My Seniors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Contact support to add a new senior to your plan.'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: MockData.seniors.length,
        itemBuilder: (context, i) {
          final s = MockData.seniors[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SevaCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: s))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  SevaAvatar(initials: s.avatar, size: 52),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Age ${s.age} | ${s.gender} | ${s.mobility}',
                      style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                  ])),
                  StatusBadge(status: s.status),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: SevaColors.textTertiary),
                  const SizedBox(width: 4),
                  Text('${s.zone}, ${s.city}', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.person_outline, size: 14, color: SevaColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(s.careAide, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                ]),
                const SizedBox(height: 12),
                // Mini vitals row
                Row(children: [
                  _miniVital('BP', s.vitals['bp'], SevaColors.primary),
                  const SizedBox(width: 8),
                  _miniVital('SpO2', '${s.vitals['spo2']}%', SevaColors.green),
                  const SizedBox(width: 8),
                  _miniVital('HR', '${s.vitals['heartRate']}', SevaColors.purple),
                  const SizedBox(width: 8),
                  _miniVital('Temp', '${s.vitals['temp']}°F', SevaColors.orange),
                ]),
                const SizedBox(height: 12),
                // Conditions
                Wrap(spacing: 6, runSpacing: 6, children: s.conditions.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: SevaColors.redLight, borderRadius: BorderRadius.circular(6)),
                  child: Text(c, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: SevaColors.red)),
                )).toList()),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _miniVital(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text('$label $value', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
