import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utils/theme.dart';
import '../../controllers/medicines_controller.dart';
import '../../models/medicine.dart';
import '../../utils/app_logger.dart';
import '../../widgets/seva_widgets.dart';

class MedicineReminderScreen extends StatelessWidget {
  const MedicineReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MedicinesController());

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        switch (controller.state.value) {
          case MedicinesState.loading:
            return const Center(
              child: CircularProgressIndicator(color: SevaColors.primary),
            );
          case MedicinesState.error:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: SevaColors.red),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage.value,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        AppLogger.i('[MedicineReminderScreen] Retry clicked');
                        controller.fetchMedicines();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          case MedicinesState.empty:
            return RefreshIndicator(
              onRefresh: () async {
                AppLogger.i('[MedicineReminderScreen] Pull-to-refresh triggered');
                await controller.fetchMedicines(isSilent: true);
              },
              color: SevaColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No Medicines Scheduled',
                    subtitle: 'No medications are scheduled at the moment.',
                  ),
                ],
              ),
            );
          case MedicinesState.success:
            final meds = controller.medicines;
            final taken = meds.where((m) => m.taken).length;
            final total = meds.length;

            // Group medicines by morning vs evening (AM vs PM) based on scheduledTime or existing mock sections
            final morningMeds = meds.where((m) {
              final hourVal = int.tryParse(m.scheduledTime.split(':').first) ?? 0;
              return hourVal < 12;
            }).toList();

            final afternoonEveningMeds = meds.where((m) {
              final hourVal = int.tryParse(m.scheduledTime.split(':').first) ?? 0;
              return hourVal >= 12;
            }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                AppLogger.i('[MedicineReminderScreen] Pull-to-refresh triggered');
                await controller.fetchMedicines(isSilent: true);
              },
              color: SevaColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Progress card
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [SevaColors.purple, Color(0xFF9333EA)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: SevaColors.purple.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Today's Medicines", style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('$taken of $total taken', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 8),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? taken / total : 0.0,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            color: Colors.white,
                            minHeight: 6,
                          ),
                        ),
                      ])),
                      const SizedBox(width: 16),
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.medication, color: Colors.white, size: 32),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Morning Section
                  if (morningMeds.isNotEmpty) ...[
                    _timeSection(context, controller, 'Morning', Icons.wb_sunny, SevaColors.amber, SevaColors.amberLight, morningMeds),
                    const SizedBox(height: 20),
                  ],

                  // Afternoon / Evening Section
                  if (afternoonEveningMeds.isNotEmpty) ...[
                    _timeSection(context, controller, 'Afternoon / Evening', Icons.nights_stay, SevaColors.primary, SevaColors.primaryLight, afternoonEveningMeds),
                    const SizedBox(height: 24),
                  ],

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: SevaColors.amberLight, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SevaColors.amber.withValues(alpha: 0.3))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, size: 18, color: SevaColors.amber),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'Always take medicines as prescribed by your doctor. Contact your care aide if you feel unwell after taking any medicine.',
                        style: GoogleFonts.inter(fontSize: 12, color: SevaColors.amber, height: 1.4),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            );
        }
      }),
    );
  }

  Widget _timeSection(BuildContext context, MedicinesController controller, String title, IconData icon, Color color, Color bg, List<Medicine> meds) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
      ]),
      const SizedBox(height: 12),
      ...meds.map((med) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () async {
              await controller.toggleMedicineTaken(med.id, med.taken);
              final isNowTaken = !med.taken;
              if (isNowTaken && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('${med.name} marked as taken'),
                  ]),
                  behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: med.taken ? SevaColors.greenLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: med.taken ? SevaColors.green.withValues(alpha: 0.3) : SevaColors.border),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: med.taken ? SevaColors.green : SevaColors.purpleLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    med.taken ? Icons.check : Icons.medication,
                    color: med.taken ? Colors.white : SevaColors.purple, size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(med.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,
                    color: med.taken ? SevaColors.textSecondary : SevaColors.textPrimary,
                    decoration: med.taken ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 2),
                  Text('${med.dosage} | ${med.frequency}', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
                  if (med.prescribedBy != null && med.prescribedBy!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('Prescribed by: ${med.prescribedBy}', style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                    ),
                  if (med.notes != null && med.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(med.notes!, style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: SevaColors.textTertiary)),
                    ),
                ])),
                Column(children: [
                  Text(med.scheduledTime, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: med.taken ? SevaColors.green.withValues(alpha: 0.15) : SevaColors.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(med.taken ? 'Taken' : 'Pending',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                        color: med.taken ? SevaColors.green : SevaColors.textTertiary)),
                  ),
                ]),
              ]),
            ),
          ),
        );
      }),
    ]);
  }
}
