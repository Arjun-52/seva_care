import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/mock_data.dart'; // import for Senior type
import '../../repositories/senior_repository.dart';
import '../../services/dependency_injection.dart';
import '../../controllers/video_controller.dart';

class ScheduleVideoCallDialog extends StatefulWidget {
  final Senior preSelectedSenior;

  const ScheduleVideoCallDialog({super.key, required this.preSelectedSenior});

  @override
  State<ScheduleVideoCallDialog> createState() => _ScheduleVideoCallDialogState();
}

class _ScheduleVideoCallDialogState extends State<ScheduleVideoCallDialog> {
  final VideoController _controller = Get.put(VideoController());
  late String _selectedSeniorId;
  List<Senior> _seniors = [];
  bool _loadingSeniors = true;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedSeniorId = widget.preSelectedSenior.id;
    _loadSeniors();
  }

  Future<void> _loadSeniors() async {
    try {
      final res = await locator<SeniorRepository>().getSeniors();
      if (mounted) {
        setState(() {
          _seniors = res.seniors.isNotEmpty ? res.seniors : [widget.preSelectedSenior];
          // Ensure widget.preSelectedSenior is in the list
          if (!_seniors.any((s) => s.id == widget.preSelectedSenior.id)) {
            _seniors.insert(0, widget.preSelectedSenior);
          }
          _loadingSeniors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _seniors = [widget.preSelectedSenior];
          _loadingSeniors = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SevaColors.primary,
              onPrimary: Colors.white,
              onSurface: SevaColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SevaColors.primary,
              onPrimary: Colors.white,
              onSurface: SevaColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submit() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select both date and time'),
        backgroundColor: SevaColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Scheduled time must be in the future'),
        backgroundColor: SevaColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final success = await _controller.scheduleCall(
      seniorId: _selectedSeniorId,
      scheduledAt: scheduledDateTime,
    );

    if (success && mounted) {
      Navigator.pop(context); // Close selection dialog
      // Show Success Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.check_circle, color: SevaColors.green, size: 28),
            const SizedBox(width: 10),
            Text('Video Call Scheduled', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Video Call Scheduled Successfully', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Scheduled Date: ${_selectedDate!.toLocal().toString().substring(0, 10)}'),
              const SizedBox(height: 6),
              Text('Scheduled Time: ${_selectedTime!.format(context)}'),
              const SizedBox(height: 6),
              Text('Meeting Status: ${_controller.callStatus.value}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('ok')),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Something went wrong'),
        backgroundColor: SevaColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _startInstantCall() async {
    final success = await _controller.startInstantCall(
      seniorId: _selectedSeniorId,
    );

    if (success && mounted) {
      Navigator.pop(context); // Close selection dialog
      // Show Success Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.check_circle, color: SevaColors.green, size: 28),
            const SizedBox(width: 10),
            Text('Video Call Started', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Video Call Started Successfully', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Call Status: ${_controller.callStatus.value}'),
              const SizedBox(height: 6),
              Text('Call Started Time: ${_controller.activeCall.value?.startedAt.toLocal().toString().substring(0, 19)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('ok')),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Something went wrong'),
        backgroundColor: SevaColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.videocam, color: SevaColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Text('Schedule Video Call', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Senior Selector
              Text('Select Senior', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
              const SizedBox(height: 8),
              _loadingSeniors
                  ? const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator(color: SevaColors.primary)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SevaColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSeniorId,
                          isExpanded: true,
                          items: _seniors.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(s.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSeniorId = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 16),

              // Date Picker Button
              Text('Select Date', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_selectedDate == null
                      ? 'Pick Date'
                      : _selectedDate!.toLocal().toString().substring(0, 10)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time Picker Button
              Text('Select Time', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_selectedTime == null
                      ? 'Pick Time'
                      : _selectedTime!.format(context)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button (Schedule)
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _controller.submitting.value ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SevaColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _controller.submitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Schedule Call'),
                ),
              )),
              const SizedBox(height: 12),

              // Instant Call Button (Call Now)
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _controller.submitting.value ? null : _startInstantCall,
                  icon: const Icon(Icons.phone_forwarded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SevaColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  label: _controller.submitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Call Now'),
                ),
              )),
              const SizedBox(height: 8),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
