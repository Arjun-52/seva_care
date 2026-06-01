import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Splash / Onboarding / Login
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

// Admin
import '../screens/admin/admin_home.dart';

// Senior
import '../screens/senior/senior_home.dart';
import '../screens/senior/medicine_reminder_screen.dart';
import '../screens/senior/contacts_screen.dart';

// Family
import '../screens/family/family_home.dart';
import '../screens/shared/senior_detail_screen.dart';

// Aide
import '../screens/aide/aide_home.dart';
import '../screens/aide/record_vitals_screen.dart';
import '../screens/aide/visit_summary_screen.dart';

// Settings
import '../screens/settings/settings_screen.dart';
import '../screens/settings/help_support_screen.dart';

import '../models/mock_data.dart'; // import for Senior type

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // ─── Core / Splash ─────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // ─── Admin Module ──────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHome(),
      ),

      // ─── Senior Module ─────────────────────────
      GoRoute(
        path: '/senior',
        builder: (context, state) => const SeniorHome(),
        routes: [
          GoRoute(
            path: 'meds',
            builder: (context, state) => const MedicineReminderScreen(),
          ),
          GoRoute(
            path: 'contacts',
            builder: (context, state) => const ContactsScreen(),
          ),
        ],
      ),

      // ─── Family Module ─────────────────────────
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyHome(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) {
              final senior = state.extra as Senior;
              return SeniorDetailScreen(senior: senior);
            },
          ),
        ],
      ),

      // ─── Aide Module ───────────────────────────
      GoRoute(
        path: '/aide',
        builder: (context, state) => const AideHome(),
        routes: [
          GoRoute(
            path: 'vitals',
            builder: (context, state) => const RecordVitalsScreen(),
          ),
          GoRoute(
            path: 'summary',
            builder: (context, state) => const VisitSummaryScreen(),
          ),
        ],
      ),

      // ─── Settings Module ───────────────────────
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'support',
            builder: (context, state) => const HelpSupportScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
}
