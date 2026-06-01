import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class SeniorDetailScreen extends StatelessWidget {
  final Senior senior;
  const SeniorDetailScreen({super.key, required this.senior});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      body: CustomScrollView(slivers: [
        // Gradient app bar
        SliverAppBar(
          expandedHeight: 220, pinned: true,
          backgroundColor: SevaColors.primary,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: SevaColors.sevaGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Row(children: [
                      SevaAvatar(initials: senior.avatar, size: 64, bgColor: Colors.white24),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(senior.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Age ${senior.age} | ${senior.gender} | ${senior.mobility}',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text('${senior.zone}, ${senior.city}', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
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
                StatusBadge(status: senior.status),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: SevaColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text(senior.tier, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: SevaColors.primary)),
                ),
              ]),
              const SizedBox(height: 20),

              // Vitals Section
              const SectionTitle(title: 'Current Vitals', icon: Icons.monitor_heart),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
                children: [
                  VitalCard(label: 'Blood Pressure', value: senior.vitals['bp'], subtitle: 'mmHg',
                    icon: Icons.monitor_heart, color: SevaColors.primary, bgColor: SevaColors.primaryLight),
                  VitalCard(label: 'SpO2', value: '${senior.vitals['spo2']}%', subtitle: 'Oxygen',
                    icon: Icons.favorite, color: SevaColors.green, bgColor: SevaColors.greenLight),
                  VitalCard(label: 'Heart Rate', value: '${senior.vitals['heartRate']} bpm', subtitle: 'Resting',
                    icon: Icons.trending_up, color: SevaColors.purple, bgColor: SevaColors.purpleLight),
                  VitalCard(label: 'Temperature', value: '${senior.vitals['temp']}°F', subtitle: 'Body',
                    icon: Icons.thermostat, color: SevaColors.orange, bgColor: SevaColors.orangeLight),
                ],
              ),
              const SizedBox(height: 24),

              // Health Conditions
              const SectionTitle(title: 'Health Conditions', icon: Icons.medical_information),
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
              const SizedBox(height: 24),

              // Care Info
              const SectionTitle(title: 'Care Information', icon: Icons.info_outline),
              const SizedBox(height: 12),
              SevaCard(padding: EdgeInsets.zero, child: Column(children: [
                _infoRow(Icons.person, 'Care Aide', senior.careAide),
                const Divider(height: 1, color: SevaColors.divider, indent: 52),
                _infoRow(Icons.phone, 'Phone', senior.phone),
                const Divider(height: 1, color: SevaColors.divider, indent: 52),
                if (senior.nriContact != null) ...[
                  _infoRow(Icons.flight, 'NRI Contact', senior.nriContact!),
                  const Divider(height: 1, color: SevaColors.divider, indent: 52),
                ],
                _infoRow(Icons.accessible, 'Mobility', senior.mobility),
                const Divider(height: 1, color: SevaColors.divider, indent: 52),
                _infoRow(Icons.badge, 'ID', senior.id),
              ])),
              const SizedBox(height: 24),

              // IoT Devices
              const SectionTitle(title: 'Connected Devices', icon: Icons.devices),
              const SizedBox(height: 12),
              ...MockData.iotDevices.take(4).map((device) => Padding(
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

              // Action Buttons
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Calling ${senior.careAide}...'),
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
      ]),
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
}
