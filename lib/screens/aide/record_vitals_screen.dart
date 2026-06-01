import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';

class RecordVitalsScreen extends StatefulWidget {
  const RecordVitalsScreen({super.key});

  @override
  State<RecordVitalsScreen> createState() => _RecordVitalsScreenState();
}

class _RecordVitalsScreenState extends State<RecordVitalsScreen> {
  final _systolicController = TextEditingController(text: '130');
  final _diastolicController = TextEditingController(text: '82');
  final _spo2Controller = TextEditingController(text: '96');
  final _heartRateController = TextEditingController(text: '72');
  final _tempController = TextEditingController(text: '98.2');
  final _notesController = TextEditingController();
  String _mood = 'Normal';
  bool _submitting = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _spo2Controller.dispose();
    _heartRateController.dispose();
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text('Vitals recorded successfully!'),
      ]),
      behavior: SnackBarBehavior.floating,
      backgroundColor: SevaColors.green,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: const Text('Record Vitals')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Senior info card
          GradientHeader(child: Row(children: [
            const SevaAvatar(initials: 'KD', size: 44, bgColor: Colors.white24),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kamla Devi Sharma', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Age 78 | Vaishali Nagar, Jaipur', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ]),
          ])),
          const SizedBox(height: 24),

          // Blood Pressure
          const SectionTitle(title: 'Blood Pressure', icon: Icons.monitor_heart),
          const SizedBox(height: 12),
          SevaCard(child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Systolic (mmHg)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _systolicController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: SevaColors.primary),
                decoration: InputDecoration(
                  filled: true, fillColor: SevaColors.primaryLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('/', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w300, color: SevaColors.textTertiary)),
            ),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Diastolic (mmHg)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _diastolicController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: SevaColors.primary),
                decoration: InputDecoration(
                  filled: true, fillColor: SevaColors.primaryLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ])),
          ])),
          const SizedBox(height: 20),

          // SpO2 & Heart Rate
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.favorite, size: 16, color: SevaColors.green),
                const SizedBox(width: 6),
                Text('SpO2 (%)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _spo2Controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: SevaColors.green),
                decoration: InputDecoration(
                  filled: true, fillColor: SevaColors.greenLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ])),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.trending_up, size: 16, color: SevaColors.purple),
                const SizedBox(width: 6),
                Text('Heart Rate (bpm)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _heartRateController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: SevaColors.purple),
                decoration: InputDecoration(
                  filled: true, fillColor: SevaColors.purpleLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 20),

          // Temperature
          Row(children: [
            const Icon(Icons.thermostat, size: 16, color: SevaColors.orange),
            const SizedBox(width: 6),
            Text('Temperature (°F)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: TextField(
              controller: _tempController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: SevaColors.orange),
              decoration: InputDecoration(
                filled: true, fillColor: SevaColors.orangeLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mood
          Text('Patient Mood', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            for (var mood in ['Happy', 'Normal', 'Tired', 'Unwell'])
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _mood = mood),
                child: Container(
                  margin: EdgeInsets.only(right: mood != 'Unwell' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _mood == mood ? SevaColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _mood == mood ? SevaColors.primary : SevaColors.border),
                  ),
                  child: Column(children: [
                    Text(_moodEmoji(mood), style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(mood, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _mood == mood ? Colors.white : SevaColors.textSecondary)),
                  ]),
                ),
              )),
          ]),
          const SizedBox(height: 20),

          // Notes
          Text('Notes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add any observations...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity, height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: SevaColors.sevaGradient, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: SevaColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent),
                child: _submitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Save Vitals', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  String _moodEmoji(String mood) {
    switch (mood) {
      case 'Happy': return '\u{1F60A}';
      case 'Normal': return '\u{1F610}';
      case 'Tired': return '\u{1F634}';
      case 'Unwell': return '\u{1F912}';
      default: return '\u{1F610}';
    }
  }
}
