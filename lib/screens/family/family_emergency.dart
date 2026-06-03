import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/emergency_alerts_response.dart';
import '../../repositories/senior_repository.dart';
import '../../services/dependency_injection.dart';
import '../../controllers/emergency_controller.dart';

class FamilyEmergency extends StatefulWidget {
  const FamilyEmergency({super.key});

  @override
  State<FamilyEmergency> createState() => _FamilyEmergencyState();
}

class _FamilyEmergencyState extends State<FamilyEmergency> {
  final EmergencyController _controller = Get.put(EmergencyController());
  final ScrollController _scrollController = ScrollController();
  String? _seniorId;
  bool _loadingSenior = true;

  @override
  void initState() {
    super.initState();
    _loadSenior();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _controller.fetchEmergencyAlerts();
    }
  }

  Future<void> _loadSenior() async {
    try {
      final seniorsResponse = await locator<SeniorRepository>().getSeniors();
      if (seniorsResponse.seniors.isNotEmpty) {
        if (mounted) {
          setState(() {
            _seniorId = seniorsResponse.seniors.first.id;
            _loadingSenior = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingSenior = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSenior = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSenior) {
      return Scaffold(
        backgroundColor: SevaColors.background,
        appBar: AppBar(title: Text(t('emergency'))),
        body: const Center(
          child: CircularProgressIndicator(color: SevaColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: Text(t('emergency'))),
      body: Obx(() {
        if (_controller.state.value == EmergencyState.loading && _controller.emergencyAlerts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: SevaColors.primary),
          );
        }

        if (_controller.state.value == EmergencyState.error && _controller.emergencyAlerts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: SevaColors.red),
                  const SizedBox(height: 16),
                  Text(
                    _controller.errorMessage.value,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _controller.fetchEmergencyAlerts(isRefresh: true);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (_controller.state.value == EmergencyState.success && _controller.emergencyAlerts.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              await _controller.fetchEmergencyAlerts(isRefresh: true);
            },
            color: SevaColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                const EmptyState(
                  icon: Icons.emergency_outlined,
                  title: 'No Emergency Alerts',
                  subtitle: 'No emergency alerts have been reported.',
                ),
              ],
            ),
          );
        }

        final activeAlerts = _controller.emergencyAlerts.where((a) => a.status != 'resolved').toList();
        final resolved = _controller.emergencyAlerts.where((a) => a.status == 'resolved').toList();

        return RefreshIndicator(
          onRefresh: () async {
            await _controller.fetchEmergencyAlerts(isRefresh: true);
          },
          color: SevaColors.primary,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
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
                          Text(alert.senior?.name ?? 'Senior', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
                        ])),
                        StatusBadge(status: alert.status),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: SevaColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(alert.senior?.city ?? '', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.phone, size: 14, color: SevaColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(alert.senior?.phone ?? '', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.access_time, size: 14, color: SevaColors.textTertiary),
                        const SizedBox(width: 4),
                        Text('Created: ${alert.createdAt.toLocal().toString().substring(0, 16)}', 
                          style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                      ]),
                      const Divider(height: 16),
                      Text('Alert ID: ${alert.id}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      Text('Trigger Source: ${alert.triggeredBy}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      if (alert.etaMinutes != null)
                        Text('Response ETA: ${alert.etaMinutes} mins', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      if (alert.resolutionNotes != null && alert.resolutionNotes!.isNotEmpty)
                        Text('Resolution Notes: ${alert.resolutionNotes}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      if (alert.responseTimeMinutes != null)
                        Text('Response Time: ${alert.responseTimeMinutes} mins', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      if (alert.escalatedTo != null && alert.escalatedTo!.isNotEmpty)
                        Text('Escalation Info: ${alert.escalatedTo}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
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
                      Text('${a.type} — ${a.senior?.name ?? "Senior"}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(a.resolutionNotes ?? 'Resolved alert details', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                    ])),
                    const StatusBadge(status: 'completed'),
                  ])),
                )),
              ],

              // Load more indicator at bottom
              if (_controller.loadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: SevaColors.primary)),
                ),
            ]),
          ),
        );
      }),
    );
  }

  void _showSOSDialog(BuildContext context) {
    if (_seniorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No senior citizen selected'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SevaColors.red,
      ));
      return;
    }

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
          onPressed: _controller.submitting.value ? null : () async {
            Navigator.pop(ctx);
            
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (loadingCtx) => const Center(
                child: CircularProgressIndicator(color: SevaColors.primary),
              ),
            );

            final success = await _controller.triggerSOS(seniorId: _seniorId!);
            
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
                        Text('Alert ID: ${_controller.alertId.value}', style: GoogleFonts.inter(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Status: ${_controller.alertStatus.value}', style: GoogleFonts.inter(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Emergency Number: ${_controller.emergencyNumber.value}', style: GoogleFonts.inter(fontSize: 14)),
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
                    content: Text(_controller.errorMessage.value.isNotEmpty 
                      ? _controller.errorMessage.value 
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
          child: _controller.submitting.value
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
