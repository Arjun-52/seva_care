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
import '../../core/storage/local_storage_service.dart';
import '../../services/dependency_injection.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import '../../core/api/api_client.dart';
import '../../models/user_model.dart';
import '../settings/edit_profile_screen.dart';

class FamilyProfile extends StatefulWidget {
  const FamilyProfile({super.key});

  @override
  State<FamilyProfile> createState() => _FamilyProfileState();
}

class _FamilyProfileState extends State<FamilyProfile> {
  bool _loading = false;
  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _fetchProfile();
  }

  void _loadCachedProfile() {
    final storage = locator<LocalStorageService>();
    final id = storage.getUserId();
    if (id != null && id.isNotEmpty) {
      setState(() {
        _profile = UserModel(
          id: id,
          name: storage.getUserName() ?? '',
          email: storage.getUserEmail() ?? '',
          role: storage.getUserRole() ?? 'family',
          phone: storage.getUserPhone() ?? '',
          avatar: storage.getUserAvatar() ?? '',
          country: storage.getUserCountry(),
          timezone: storage.getUserTimezone(),
          language: storage.getUserLanguage(),
          status: storage.getUserStatus(),
        );
      });
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    AppLogger.i('Fetch profile started');

    try {
      final result = await locator<ApiClient>().get('auth/me');
      if (result.success && result.data != null) {
        final profileUser = UserModel.fromJson(result.data as Map<String, dynamic>);
        
        final storage = locator<LocalStorageService>();
        await storage.saveUserId(profileUser.id);
        await storage.saveUserName(profileUser.name);
        await storage.saveUserEmail(profileUser.email);
        await storage.saveUserRole(profileUser.role);
        await storage.saveUserPhone(profileUser.phone);
        await storage.saveUserAvatar(profileUser.avatar);
        await storage.saveUserCountry(profileUser.country);
        await storage.saveUserTimezone(profileUser.timezone);
        await storage.saveUserLanguage(profileUser.language);
        await storage.saveUserStatus(profileUser.status);
        
        AppLogger.i('Profile fetched successfully');
        AppLogger.i('Profile cache updated');

        if (mounted) {
          setState(() {
            _profile = profileUser;
          });
        }
      } else {
        AppLogger.e('Profile fetch failed: ${result.errorMessage}');
        _showErrorSnackbar(result.errorMessage);
      }
    } catch (e, stack) {
      AppLogger.e('Profile fetch failed with error', e, stack);
      String displayError = 'Something went wrong. Please try again.';
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        displayError = 'Unable to connect. Please check internet connection.';
      }
      _showErrorSnackbar(displayError);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: SevaColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryStr = _profile?.country ?? 'Not specified';
    final timezoneStr = _profile?.timezone ?? 'Not specified';
    final languageStr = _profile?.language ?? 'Not specified';
    final statusStr = _profile?.status ?? 'Not specified';

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: Text(t('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (updated == true) {
                _fetchProfile();
              }
            },
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: SevaColors.primary, strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          AppLogger.i('Profile refresh triggered');
          await _fetchProfile();
        },
        color: SevaColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Profile Header
            SevaCard(child: Column(children: [
              SevaAvatar(
                initials: _profile?.avatar.isNotEmpty == true ? _profile!.avatar : 'A',
                size: 72,
                bgColor: SevaColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                _profile?.name.isNotEmpty == true ? _profile!.name : 'User Profile',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: SevaColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    countryStr,
                    style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${_profile?.role.isNotEmpty == true ? _profile!.role.toUpperCase() : t('family')} Account',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.primary),
                ),
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

            // Account Information (Live API Data Bindings)
            SevaCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                    child: Text(
                      'Account Information',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
                    ),
                  ),
                  _infoItem(Icons.email_outlined, t('email'), _profile?.email ?? 'Not specified'),
                  _infoDivider(),
                  _infoItem(Icons.phone_outlined, t('phone'), _profile?.phone ?? 'Not specified'),
                  _infoDivider(),
                  _infoItem(Icons.public, 'Country', countryStr),
                  _infoDivider(),
                  _infoItem(Icons.schedule, 'Timezone', timezoneStr),
                  _infoDivider(),
                  _infoItem(Icons.translate, 'Language', languageStr),
                  _infoDivider(),
                  _statusItem(statusStr),
                ],
              ),
            ),
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
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SevaColors.textSecondary),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: SevaColors.textSecondary)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _statusItem(String status) {
    final isActive = status.toLowerCase() == 'active';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, size: 20, color: SevaColors.textSecondary),
          const SizedBox(width: 14),
          Text('Status', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: SevaColors.textSecondary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? SevaColors.green.withAlpha(30) : SevaColors.red.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? SevaColors.green : SevaColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDivider() => const Divider(height: 1, color: SevaColors.divider, indent: 50);

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
    bool loading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('${t('sign_out')}?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            content: loading
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(color: SevaColors.primary),
                    ),
                  )
                : Text(t('sign_out_confirm'), style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
            actions: loading
                ? []
                : [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => loading = true);
                        AppLogger.i('Logout initiated');
                        
                        final storage = locator<LocalStorageService>();
                        
                        try {
                          AppLogger.i('Logout API called');
                          final result = await locator<ApiClient>().post('auth/logout');
                          
                          if (result.success) {
                            AppLogger.i('Logout successful');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Logged out successfully'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: SevaColors.green,
                              ));
                            }
                          } else {
                            AppLogger.e('Logout API failed: ${result.errorMessage}');
                          }
                        } catch (e, stack) {
                          AppLogger.e('Logout API failed with error', e, stack);
                        } finally {
                          AppLogger.i('Forced local logout executed, clearing session');
                          await storage.clearSession();
                          ApiService.clearTokens();
                          AppLogger.i('Local session cleared');
                          
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          
                          AppLogger.i('Navigation to login');
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red),
                      child: Text(t('sign_out')),
                    ),
                  ],
          );
        },
      ),
    );
  }
}
