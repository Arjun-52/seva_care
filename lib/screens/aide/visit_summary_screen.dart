import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class VisitSummaryScreen extends StatefulWidget {
  const VisitSummaryScreen({super.key});

  @override
  State<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends State<VisitSummaryScreen> {
  final _notesController = TextEditingController();
  bool _submitting = false;
  int _rating = 0;
  final List<String> _uploadedPhotos = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: SevaColors.greenLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: SevaColors.green, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Visit Completed!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Summary sent to family and Seva admin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
        ]),
        actions: [
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: SevaColors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Done'),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = MockData.careLogs;
    final completed = tasks.where((t) => t.status == 'completed').length;

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: const Text('Visit Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Senior Info
          GradientHeader(child: Row(children: [
            const SevaAvatar(initials: 'KD', size: 44, bgColor: Colors.white24),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kamla Devi Sharma', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Visit Duration: 4h 30m', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('$completed/${tasks.length} tasks', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ])),
          const SizedBox(height: 20),

          // Task Summary
          const SectionTitle(title: 'Tasks Completed', icon: Icons.checklist),
          const SizedBox(height: 12),
          SevaCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: SevaColors.divider),
              itemBuilder: (_, i) {
                final t = tasks[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Icon(
                      t.status == 'completed' ? Icons.check_circle : t.status == 'active' ? Icons.play_circle : Icons.schedule,
                      size: 20,
                      color: t.status == 'completed' ? SevaColors.green : t.status == 'active' ? SevaColors.primary : SevaColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t.activity, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                      color: t.status == 'completed' ? SevaColors.textSecondary : SevaColors.textPrimary,
                      decoration: t.status == 'completed' ? TextDecoration.lineThrough : null))),
                    Text(t.time, style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Vitals Recorded
          const SectionTitle(title: 'Vitals Recorded', icon: Icons.monitor_heart),
          const SizedBox(height: 12),
          Row(children: [
            _vitalSummary('BP', '130/82', 'mmHg', SevaColors.primary, SevaColors.primaryLight),
            const SizedBox(width: 10),
            _vitalSummary('SpO2', '96%', 'Normal', SevaColors.green, SevaColors.greenLight),
            const SizedBox(width: 10),
            _vitalSummary('HR', '72', 'bpm', SevaColors.purple, SevaColors.purpleLight),
          ]),
          const SizedBox(height: 20),

          // Photo Proof
          const SectionTitle(title: 'Photo Proof', icon: Icons.camera_alt),
          const SizedBox(height: 12),
          Row(children: [
            GestureDetector(
              onTap: () {
                setState(() => _uploadedPhotos.add('Visit Photo ${_uploadedPhotos.length + 1}'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Photo added (demo)'), behavior: SnackBarBehavior.floating,
                ));
              },
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: SevaColors.divider, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SevaColors.border, style: BorderStyle.solid),
                ),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_a_photo, color: SevaColors.textTertiary, size: 24),
                  SizedBox(height: 4),
                  Text('Add', style: TextStyle(fontSize: 10, color: SevaColors.textTertiary)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            ..._uploadedPhotos.map((p) => Container(
              width: 80, height: 80, margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: SevaColors.greenLight, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SevaColors.green.withValues(alpha: 0.3)),
              ),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle, color: SevaColors.green, size: 24),
                SizedBox(height: 4),
                Text('Uploaded', style: TextStyle(fontSize: 10, color: SevaColors.green)),
              ]),
            )),
          ]),
          const SizedBox(height: 20),

          // Patient Rating
          Text('Patient Condition Rating', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
            GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(i < _rating ? Icons.star : Icons.star_border, size: 40,
                  color: i < _rating ? SevaColors.amber : SevaColors.border),
              ),
            ),
          )),
          if (_rating > 0)
            Center(child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _rating <= 2 ? 'Needs attention' : _rating <= 3 ? 'Fair condition' : _rating == 4 ? 'Good condition' : 'Excellent condition',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _rating <= 2 ? SevaColors.red : _rating <= 3 ? SevaColors.amber : SevaColors.green),
              ),
            )),
          const SizedBox(height: 20),

          // Visit Notes
          Text('Visit Notes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Summarize the visit, any concerns, special observations...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity, height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [SevaColors.green, SevaColors.teal]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: SevaColors.green.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent),
                child: _submitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.send, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Submit Visit Summary', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _vitalSummary(String label, String value, String unit, Color color, Color bg) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(unit, style: GoogleFonts.inter(fontSize: 10, color: color.withValues(alpha: 0.7))),
      ]),
    ));
  }
}
