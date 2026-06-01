import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import 'family_dashboard.dart';
import 'family_vitals.dart';
import 'family_care_logs.dart';
import 'family_emergency.dart';
import 'family_profile.dart';

class FamilyHome extends StatefulWidget {
  const FamilyHome({super.key});

  @override
  State<FamilyHome> createState() => _FamilyHomeState();
}

class _FamilyHomeState extends State<FamilyHome> {
  int _currentIndex = 0;

  final _screens = const [
    FamilyDashboard(),
    FamilyVitals(),
    FamilyCareLogs(),
    FamilyEmergency(),
    FamilyProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.dashboard_rounded, t('home'), 0),
                _navItem(Icons.monitor_heart_outlined, t('vitals'), 1),
                _navItem(Icons.checklist_rounded, t('care_log'), 2),
                _navItem(Icons.emergency_outlined, t('sos'), 3),
                _navItem(Icons.person_outline_rounded, t('profile'), 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? SevaColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? SevaColors.primary : SevaColors.textTertiary, size: 22),
          const SizedBox(height: 3),
          Text(label,
            style: TextStyle(
              fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? SevaColors.primary : SevaColors.textTertiary,
            ),
          ),
          if (index == 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: SevaColors.red, shape: BoxShape.circle)),
            ),
        ]),
      ),
    );
  }
}
