import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class FamilyCareLogs extends StatelessWidget {
  const FamilyCareLogs({super.key});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'check-in': return Icons.visibility;
      case 'medicine': return Icons.medication;
      case 'hygiene': return Icons.water_drop;
      case 'meal': return Icons.restaurant;
      case 'therapy': return Icons.sports_gymnastics;
      case 'vitals': return Icons.monitor_heart;
      case 'monitoring': return Icons.wifi;
      default: return Icons.schedule;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'check-in': return SevaColors.primary;
      case 'medicine': return SevaColors.purple;
      case 'hygiene': return SevaColors.teal;
      case 'meal': return SevaColors.orange;
      case 'therapy': return SevaColors.green;
      case 'vitals': return SevaColors.red;
      case 'monitoring': return SevaColors.textSecondary;
      default: return SevaColors.textTertiary;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'check-in': return SevaColors.primaryLight;
      case 'medicine': return SevaColors.purpleLight;
      case 'hygiene': return SevaColors.tealLight;
      case 'meal': return SevaColors.orangeLight;
      case 'therapy': return SevaColors.greenLight;
      case 'vitals': return SevaColors.redLight;
      case 'monitoring': return SevaColors.divider;
      default: return SevaColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = MockData.careLogs;
    final completed = logs.where((l) => l.status == 'completed').length;
    final active = logs.where((l) => l.status == 'active').length;
    final pending = logs.where((l) => l.status == 'pending').length;

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: Text(t('care_logs'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kamla Devi Sharma', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
          const SizedBox(height: 16),

          // Day Selector
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (var d in ['May 18', 'May 19', t('today')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: d == t('today') ? SevaColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: d != t('today') ? Border.all(color: SevaColors.border) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(d,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                        color: d == t('today') ? Colors.white : SevaColors.textSecondary)),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Summary Stats
          Row(children: [
            _statChip(t('completed'), '$completed', SevaColors.green, SevaColors.greenLight),
            const SizedBox(width: 8),
            _statChip(t('active'), '$active', SevaColors.primary, SevaColors.primaryLight),
            const SizedBox(width: 8),
            _statChip(t('pending'), '$pending', SevaColors.textTertiary, SevaColors.divider),
            const SizedBox(width: 8),
            _statChip('Total', '${logs.length}', SevaColors.purple, SevaColors.purpleLight),
          ]),
          const SizedBox(height: 20),

          // Log List
          SevaCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: SevaColors.divider),
              itemBuilder: (context, i) {
                final log = logs[i];
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _typeBg(log.type), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_typeIcon(log.type), size: 20, color: _typeColor(log.type)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(log.activity,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                            color: log.status == 'pending' ? SevaColors.textTertiary : SevaColors.textPrimary))),
                        StatusBadge(status: log.status),
                      ]),
                      const SizedBox(height: 4),
                      Text('${log.time} · ${log.who}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      if (log.notes.isNotEmpty && log.status != 'pending') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: SevaColors.divider, borderRadius: BorderRadius.circular(8)),
                          child: Text(log.notes, style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textSecondary)),
                        ),
                      ],
                    ])),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
