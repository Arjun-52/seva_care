import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../../models/senior_details_model.dart';
import '../../models/senior_vital_history_model.dart';
import '../../models/latest_vitals_model.dart';
import '../../services/dependency_injection.dart';
import '../../repositories/senior_repository.dart';
import '../../utils/app_logger.dart';
import '../family/edit_senior_screen.dart';

class SeniorDetailScreen extends StatefulWidget {
  final Senior senior;
  const SeniorDetailScreen({super.key, required this.senior});

  @override
  State<SeniorDetailScreen> createState() => _SeniorDetailScreenState();
}

class _SeniorDetailScreenState extends State<SeniorDetailScreen> {
  bool _loading = false;
  bool _deleting = false;
  String? _error;
  SeniorDetailsModel? _details;
  List<SeniorVitalHistoryModel>? _vitalsHistory;
  LatestVitalsModel? _latestVitals;

  @override
  void initState() {
    super.initState();
    _fetchSeniorDetails();
  }

  Future<void> _fetchSeniorDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        locator<SeniorRepository>().getSeniorById(widget.senior.id),
        locator<SeniorRepository>().getSeniorVitalsHistory(widget.senior.id),
        locator<SeniorRepository>().getLatestVitals(widget.senior.id),
      ]);
      
      if (mounted) {
        setState(() {
          _details = results[0] as SeniorDetailsModel;
          _vitalsHistory = results[1] as List<SeniorVitalHistoryModel>;
          _latestVitals = results[2] as LatestVitalsModel?;
        });
      }
      AppLogger.i('Senior details, history and latest vitals fetched successfully for: ${widget.senior.id}');
    } catch (e, stack) {
      AppLogger.e('Failed to fetch senior details', e, stack);
      String errMsg = e.toString().replaceFirst('Exception: ', '');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        errMsg = 'Unable to connect. Please check your internet connection.';
      }
      if (mounted) {
        setState(() {
          _error = errMsg;
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
  Future<void> _navigateToEditSenior(SeniorDetailsModel details) async {
    final success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditSeniorScreen(senior: details)),
    );
    if (success == true) {
      _fetchSeniorDetails();
    }
  }

  Future<void> _deleteSenior(String seniorId) async {
    setState(() {
      _deleting = true;
    });

    try {
      final msg = await locator<SeniorRepository>().deleteSenior(seniorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: SevaColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return success to reload Seniors screen
      }
    } catch (e, stack) {
      AppLogger.e('Delete senior failed', e, stack);
      String errMsg = e.toString().replaceFirst('Exception: ', '');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        errMsg = 'Unable to connect. Please check your internet connection.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: SevaColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  void _confirmDeleteSenior(String seniorId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Senior'),
        content: Text('Are you sure you want to remove $name? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSenior(seniorId);
            },
            style: TextButton.styleFrom(foregroundColor: SevaColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchSeniorDetails,
        color: SevaColors.primary,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_deleting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: SevaColors.primary),
            SizedBox(height: 16),
            Text('Removing senior citizen...', style: TextStyle(color: SevaColors.textSecondary)),
          ],
        ),
      );
    }

    if (_loading && _details == null) {
      return const Center(
        child: CircularProgressIndicator(color: SevaColors.primary),
      );
    }

    if (_error != null && _details == null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
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
                onPressed: _fetchSeniorDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final d = _details ?? SeniorDetailsModel(
      id: widget.senior.id,
      name: widget.senior.name,
      age: widget.senior.age,
      gender: widget.senior.gender,
      city: widget.senior.city,
      tier: widget.senior.tier,
      status: widget.senior.status,
      mobility: widget.senior.mobility,
      conditions: widget.senior.conditions,
      avatar: widget.senior.avatar,
      createdAt: widget.senior.lastCheckIn,
      updatedAt: widget.senior.lastCheckIn,
      familyLinks: [],
      vitals: [],
      medicines: [],
      iotDevices: [],
      emergencyAlerts: [],
    );

    // Get latest vitals if available
    final latestVital = _latestVitals;
    final bpText = latestVital != null && latestVital.bpSystolic != null && latestVital.bpDiastolic != null
        ? '${latestVital.bpSystolic}/${latestVital.bpDiastolic}'
        : '--';
    final spo2Text = latestVital != null && latestVital.spo2 != null
        ? '${latestVital.spo2}%'
        : '--';
    final hrText = latestVital != null && latestVital.heartRate != null
        ? '${latestVital.heartRate} bpm'
        : '--';
    final tempText = latestVital != null && latestVital.temperature != null
        ? '${latestVital.temperature}°F'
        : '--';
    final sugarText = latestVital?.bloodSugar != null ? '${latestVital!.bloodSugar} mg/dL' : '--';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Gradient app bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: SevaColors.primary,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              ),
              onPressed: _deleting ? null : () => _navigateToEditSenior(d),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline, color: SevaColors.red, size: 20),
              ),
              onPressed: _deleting ? null : () => _confirmDeleteSenior(d.id, d.name),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: SevaColors.sevaGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Row(children: [
                      SevaAvatar(initials: d.avatar.isNotEmpty ? d.avatar : 'S', size: 64, bgColor: Colors.white24),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Age ${d.age} | ${d.gender} | ${d.mobility.isNotEmpty ? d.mobility : "Not specified"}',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text('${d.zone?['name'] ?? widget.senior.zone}, ${d.city}', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                        ]),
                      ])),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Status & tier row
              Row(children: [
                StatusBadge(status: d.status),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text(d.tier, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: SevaColors.primary)),
                ),
              ]),
              const SizedBox(height: 20),

              // Vitals Section
              const SectionTitle(title: 'Latest Vitals', icon: Icons.monitor_heart),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
                children: [
                  VitalCard(label: 'Blood Pressure', value: bpText, subtitle: 'mmHg',
                    icon: Icons.monitor_heart, color: SevaColors.primary, bgColor: SevaColors.primaryLight),
                  VitalCard(label: 'SpO2', value: spo2Text, subtitle: 'Oxygen',
                    icon: Icons.favorite, color: SevaColors.green, bgColor: SevaColors.greenLight),
                  VitalCard(label: 'Heart Rate', value: hrText, subtitle: 'Resting',
                    icon: Icons.trending_up, color: SevaColors.purple, bgColor: SevaColors.purpleLight),
                  VitalCard(label: 'Temperature', value: tempText, subtitle: 'Body',
                    icon: Icons.thermostat, color: SevaColors.orange, bgColor: SevaColors.orangeLight),
                ],
              ),
              const SizedBox(height: 12),
              SevaCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop, color: SevaColors.rose, size: 20),
                        const SizedBox(width: 12),
                        Text('Blood Sugar:', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
                        const SizedBox(width: 8),
                        Text(sugarText, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.rose)),
                        const Spacer(),
                        if (latestVital?.source != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: SevaColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Source: ${latestVital!.source}',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: SevaColors.primary),
                            ),
                          ),
                      ],
                    ),
                    if (latestVital != null) ...[
                      const Divider(height: 20, color: SevaColors.divider),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: SevaColors.textTertiary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Recorded: ${_formatDate(latestVital.recordedAt)}',
                            style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Health Conditions
              if (d.conditions.isNotEmpty) ...[
                const SectionTitle(title: 'Health Conditions', icon: Icons.medical_information),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: d.conditions.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: SevaColors.redLight, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.favorite, size: 14, color: SevaColors.red),
                    const SizedBox(width: 6),
                    Text(c, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: SevaColors.red)),
                  ]),
                )).toList()),
                const SizedBox(height: 24),
              ],

              // Medicines List
              if (d.medicines.isNotEmpty) ...[
                const SectionTitle(title: 'Medicines Schedule', icon: Icons.medication_outlined),
                const SizedBox(height: 12),
                ...d.medicines.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SevaCard(
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: m.taken ? SevaColors.greenLight : SevaColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medication,
                          size: 20,
                          color: m.taken ? SevaColors.green : SevaColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${m.dosage} | ${m.frequency} | ${m.time}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: m.taken ? SevaColors.greenLight : SevaColors.amberLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.taken ? 'Taken' : 'Scheduled',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: m.taken ? SevaColors.green : SevaColors.amber,
                          ),
                        ),
                      ),
                    ]),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // Family Contacts Section
              if (d.familyLinks.isNotEmpty) ...[
                const SectionTitle(title: 'Family Contacts', icon: Icons.people_outline),
                const SizedBox(height: 12),
                ...d.familyLinks.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SevaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              f.user.name,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: f.isPrimary ? SevaColors.primaryLight : SevaColors.borderLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                f.isPrimary ? 'Primary | ${f.relation}' : f.relation,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: f.isPrimary ? SevaColors.primary : SevaColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.email_outlined, size: 14, color: SevaColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(f.user.email, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                        ]),
                        if (f.user.phone != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.phone_outlined, size: 14, color: SevaColors.textTertiary),
                            const SizedBox(width: 6),
                            Text(f.user.phone!, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // Care Info
              const SectionTitle(title: 'Care Information', icon: Icons.info_outline),
              const SizedBox(height: 12),
              SevaCard(padding: EdgeInsets.zero, child: Column(children: [
                _infoRow(Icons.person, 'Care Aide', d.careAide?['name'] ?? widget.senior.careAide),
                const Divider(height: 1, color: SevaColors.divider, indent: 52),
                _infoRow(Icons.phone, 'Phone', d.phone ?? widget.senior.phone),
                const Divider(height: 1, color: SevaColors.divider, indent: 52),
                if (widget.senior.nriContact != null) ...[
                  _infoRow(Icons.flight, 'NRI Contact', widget.senior.nriContact!),
                  const Divider(height: 1, color: SevaColors.divider, indent: 52),
                ],
                _infoRow(Icons.accessible, 'Mobility', d.mobility.isNotEmpty ? d.mobility : widget.senior.mobility),
                const Divider(height: 1, color: SevaColors.divider, indent: 52),
                _infoRow(Icons.badge, 'ID', d.id),
              ])),
              const SizedBox(height: 24),

              // IoT Devices
              if (d.iotDevices.isNotEmpty) ...[
                const SectionTitle(title: 'Connected Devices', icon: Icons.devices),
                const SizedBox(height: 12),
                ...d.iotDevices.map((device) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SevaCard(child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: device.status == 'online' ? SevaColors.greenLight : SevaColors.redLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        device.type == 'wearable' ? Icons.watch :
                        device.type == 'medical' ? Icons.monitor_heart :
                        device.type == 'safety' ? Icons.shield : Icons.hub,
                        size: 20,
                        color: device.status == 'online' ? SevaColors.green : SevaColors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(device.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(device.lastReading ?? '', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.battery_std, size: 14,
                          color: device.battery > 50 ? SevaColors.green : SevaColors.amber),
                        const SizedBox(width: 2),
                        Text('${device.battery}%', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textSecondary)),
                      ]),
                      const SizedBox(height: 2),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: device.status == 'online' ? SevaColors.green : SevaColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ]),
                  ])),
                )),
                const SizedBox(height: 24),
              ],

              // Emergency Alerts Section
              if (d.emergencyAlerts.isNotEmpty) ...[
                const SectionTitle(title: 'Emergency Alerts', icon: Icons.warning_amber_outlined),
                const SizedBox(height: 12),
                ...d.emergencyAlerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SevaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: alert.severity == 'critical' ? SevaColors.redLight : SevaColors.orangeLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alert.type.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: alert.severity == 'critical' ? SevaColors.red : SevaColors.orange,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: alert.status == 'resolved' ? SevaColors.greenLight : SevaColors.amberLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alert.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: alert.status == 'resolved' ? SevaColors.green : SevaColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (alert.responder != null)
                          Text(
                            'Responder: ${alert.responder}',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        if (alert.eta != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'ETA: ${alert.eta}',
                              style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // Vitals History Logs Section
              const SectionTitle(title: 'Vitals History Logs', icon: Icons.history),
              const SizedBox(height: 12),
              if (_vitalsHistory == null || _vitalsHistory!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No Vitals History logs recorded yet.',
                      style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textTertiary),
                    ),
                  ),
                )
              else
                ..._vitalsHistory!.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SevaCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: SevaColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                h.source?.toUpperCase() ?? 'MANUAL',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: SevaColors.primary,
                                ),
                              ),
                            ),
                            if (h.mood != null && h.mood!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: SevaColors.saffronLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Mood: ${h.mood}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: SevaColors.saffron,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              _formatDate(h.recordedAt),
                              style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (h.bpSystolic != null && h.bpDiastolic != null)
                              _miniVitalTag('BP', '${h.bpSystolic}/${h.bpDiastolic}', SevaColors.primary),
                            if (h.spo2 != null)
                              _miniVitalTag('SpO2', '${h.spo2}%', SevaColors.green),
                            if (h.heartRate != null)
                              _miniVitalTag('Heart Rate', '${h.heartRate} bpm', SevaColors.purple),
                            if (h.temperature != null)
                              _miniVitalTag('Temperature', '${h.temperature}°F', SevaColors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
              const SizedBox(height: 24),

              // Action Buttons
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Calling ${d.careAide?['name'] ?? widget.senior.careAide}...'),
                      behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                    ));
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call Aide'),
                  style: ElevatedButton.styleFrom(backgroundColor: SevaColors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Starting video call...'),
                      behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                    ));
                  },
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Video Call'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 22, color: SevaColors.textSecondary),
        const SizedBox(width: 14),
        Text('$label:', style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: SevaColors.textPrimary))),
      ]),
    );
  }

  Widget _miniVitalTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Text('$label $value', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} $month ${dt.year} ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
