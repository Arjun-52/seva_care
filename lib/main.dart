import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'services/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ─── Initialize GetIt Locator ───────────────
  await setupLocator();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const AapnoApp());
}

class AapnoApp extends StatefulWidget {
  const AapnoApp({super.key});

  @override
  State<AapnoApp> createState() => _AapnoAppState();
}

class _AapnoAppState extends State<AapnoApp> {
  @override
  void initState() {
    super.initState();
    AapnoLocalizations.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    AapnoLocalizations.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {}); // Rebuild entire app on language change
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: t('app_name'),
      debugShowCheckedModeBanner: false,
      theme: AapnoTheme.lightTheme,
      darkTheme: AapnoTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRoutes.router,
    );
  }
}
