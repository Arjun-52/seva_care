import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../../repositories/notification_repository.dart';
import '../shared/senior_detail_screen.dart';
import 'family_notifications.dart';
import 'family_seniors.dart';
import 'add_senior_screen.dart';
import '../senior/medicine_reminder_screen.dart';
import '../../services/dependency_injection.dart';
import '../../repositories/senior_repository.dart';
import '../../repositories/care_logs_repository.dart';
import '../../repositories/medicines_repository.dart';
import '../../models/latest_vitals_model.dart';
import '../../models/care_log_today_response.dart';
import '../../models/medicine.dart' hide Medicine;
import '../../utils/app_logger.dart';
import '../../controllers/emergency_controller.dart';

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  bool _loading = false;
  String? _error;
  Senior? _senior;
  LatestVitalsModel? _latestVitals;
  List<CareLog> _todayLogs = [];
  int _completedLogsCount = 0;
  List<dynamic> _medicines = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final seniorsResponse = await locator<SeniorRepository>().getSeniors();
      if (seniorsResponse.seniors.isEmpty) {
        if (mounted) {
          setState(() {
            _senior = MockData.seniors[0];
            _latestVitals = LatestVitalsModel(
              id: 'mock_latest',
              seniorId: _senior!.id,
              bpSystolic: 130,
              bpDiastolic: 82,
              spo2: 96,
              heartRate: 72,
              temperature: 98.2,
              recordedAt: DateTime.now(),
              createdAt: DateTime.now(),
            );
            _todayLogs = MockData.careLogs.where((l) => l.seniorId == _senior!.id).toList();
            _completedLogsCount = _todayLogs.where((l) => l.status == 'completed').length;
            _medicines = MockData.medicines.where((m) => m.seniorId == _senior!.id).toList();
            _loading = false;
          });
        }
        return;
      }

      final senior = seniorsResponse.seniors.first;
      
      final results = await Future.wait([
        locator<SeniorRepository>().getLatestVitals(senior.id).catchError((err) {
          AppLogger.e('Failed to fetch latest vitals for dashboard', err);
          return null;
        }),
        locator<CareLogsRepository>().getTodayCareLogs(seniorId: senior.id).catchError((err) {
          AppLogger.e('Failed to fetch today care logs for dashboard', err);
          return null;
        }),
        locator<MedicinesRepository>().getMedicines().catchError((err) {
          AppLogger.e('Failed to fetch medicines for dashboard', err);
          return null;
        }),
      ]);

      final latestVitals = results[0] as LatestVitalsModel?;
      final careLogsResponse = results[1] as CareLogTodayResponse?;
      final medicinesResponse = results[2] as MedicinesResponse?;
      final logs = careLogsResponse?.data?.logs ?? [];
      final completed = careLogsResponse?.data?.summary.completed ?? 0;
      final meds = medicinesResponse?.medicines ?? [];

      if (mounted) {
        setState(() {
          _senior = senior;
          _latestVitals = latestVitals;
          _todayLogs = logs;
          _completedLogsCount = completed;
          _medicines = meds;
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('Dashboard fetch failed', e, stack);
      String displayError = e.toString().replaceFirst('Exception: ', '');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        displayError = 'Unable to connect. Please check your internet connection.';
      }
      if (mounted) {
        setState(() {
          _error = displayError;
          _loading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return t('good_morning');
    if (hour < 17) return t('good_afternoon');
    return t('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _senior == null) {
      return const Scaffold(
        backgroundColor: SevaColors.background,
        body: Center(
          child: CircularProgressIndicator(color: SevaColors.primary),
        ),
      );
    }

    if (_error != null && _senior == null) {
      return Scaffold(
        backgroundColor: SevaColors.background,
        body: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: SevaColors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchDashboardData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_senior == null) {
      return Scaffold(
        backgroundColor: SevaColors.background,
        body: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: SevaColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_outline, size: 48, color: SevaColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Seniors Added Yet',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add your first senior family member to start monitoring health and care activities.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddSeniorScreen()),
                    );
                    if (success == true) {
                      _fetchDashboardData();
                    }
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add Senior'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final senior = _senior!;
    final logs = _todayLogs;
    final completed = _completedLogsCount;

    final bpValue = _latestVitals != null && _latestVitals!.bpSystolic != null && _latestVitals!.bpDiastolic != null
        ? '${_latestVitals!.bpSystolic}/${_latestVitals!.bpDiastolic}'
        : (senior.vitals['bp'] ?? '--');
    final spo2Value = _latestVitals?.spo2 != null
        ? '${_latestVitals!.spo2}%'
        : (senior.vitals['spo2'] != null ? '${senior.vitals['spo2']}%' : '--%');
    final hrValue = _latestVitals?.heartRate != null
        ? '${_latestVitals!.heartRate} bpm'
        : (senior.vitals['heartRate'] != null ? '${senior.vitals['heartRate']} bpm' : '-- bpm');
    final tempValue = _latestVitals?.temperature != null
        ? '${_latestVitals!.temperature}°F'
        : (senior.vitals['temp'] != null ? '${senior.vitals['temp']}°F' : '--°F');

    return Scaffold(
      backgroundColor: SevaColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: SevaColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: senior)));
                  _fetchDashboardData();
                },
                child: GradientHeader(child: Column(children: [
                  Row(children: [
                    SevaAvatar(initials: senior.avatar.isNotEmpty ? senior.avatar : 'S', size: 56, bgColor: Colors.white24),
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
                    Text('${t('care_aide')}: ${senior.careAide.isNotEmpty ? senior.careAide : "No Care Aide"}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
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
                  VitalCard(label: t('blood_pressure'), value: bpValue, subtitle: 'mmHg — ${t('normal')}',
                    icon: Icons.monitor_heart, color: const Color(0xFF1E40AF), bgColor: SevaColors.primaryLight),
                  VitalCard(label: t('oxygen_level'), value: spo2Value, subtitle: '${t('oxygen_level')} — ${t('normal')}',
                    icon: Icons.favorite, color: const Color(0xFF047857), bgColor: SevaColors.greenLight),
                  VitalCard(label: t('heart_rate'), value: hrValue, subtitle: '${t('normal')}',
                    icon: Icons.trending_up, color: const Color(0xFF6D28D9), bgColor: SevaColors.purpleLight),
                  VitalCard(label: t('temperature'), value: tempValue, subtitle: '${t('normal')}',
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
                    final name = senior.careAide.isNotEmpty ? senior.careAide : "Care Aide";
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Calling $name...'), behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                    ));
                  }),
                QuickActionButton(icon: Icons.emergency, label: t('sos'), color: SevaColors.red, bgColor: SevaColors.redLight,
                  onTap: () => _showSOSConfirm(context)),
                QuickActionButton(icon: Icons.videocam, label: t('video_call'), color: SevaColors.primary, bgColor: SevaColors.primaryLight,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Starting video call with ${senior.name}...'), behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                    ));
                  }),
                QuickActionButton(icon: Icons.medication, label: t('medicines'), color: SevaColors.purple, bgColor: SevaColors.purpleLight,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicineReminderScreen()),
                    );
                  }),
                QuickActionButton(icon: Icons.people, label: t('all_seniors'), color: SevaColors.orange, bgColor: SevaColors.orangeLight,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilySeniors()));
                    _fetchDashboardData();
                  }),
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
                child: logs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No care activities scheduled for today.',
                            style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textTertiary),
                          ),
                        ),
                      )
                    : ListView.separated(
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
              if (senior.conditions.isNotEmpty) ...[
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
              ],
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  void _showSOSConfirm(BuildContext context) {
    if (_senior == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No senior citizen selected'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SevaColors.red,
      ));
      return;
    }

    final emergencyController = Get.put(EmergencyController());
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
        Obx(() => ElevatedButton(
          onPressed: emergencyController.submitting.value ? null : () async {
            Navigator.pop(ctx);
            
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (loadingCtx) => const Center(
                child: CircularProgressIndicator(color: SevaColors.primary),
              ),
            );

            final success = await emergencyController.triggerSOS(seniorId: _senior!.id);
            
            // Dismiss loading dialog safely
            if (context.mounted) {
              Navigator.pop(context);
            }

            if (success) {
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (successCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(children: [
                      const Icon(Icons.check_circle, color: SevaColors.green, size: 28),
                      const SizedBox(width: 10),
                      Text('Emergency Alert Sent', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ]),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alert ID: ${emergencyController.alertId.value}', style: GoogleFonts.inter(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Status: ${emergencyController.alertStatus.value}', style: GoogleFonts.inter(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Emergency Number: ${emergencyController.emergencyNumber.value}', style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(successCtx),
                        child: Text(t('ok')),
                      ),
                    ],
                  ),
                );
              }
            } else {
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (errorCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(children: [
                      const Icon(Icons.error_outline, color: SevaColors.red, size: 28),
                      const SizedBox(width: 10),
                      Text('Error', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ]),
                    content: Text(emergencyController.errorMessage.value.isNotEmpty 
                      ? emergencyController.errorMessage.value 
                      : 'Something went wrong'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(errorCtx),
                        child: Text(t('ok')),
                      ),
                    ],
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red),
          child: emergencyController.submitting.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(t('trigger_sos')),
        )),
      ],
    ));
  }
}

