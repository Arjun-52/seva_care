import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart'; // for Senior type
import '../../repositories/senior_repository.dart';
import '../../services/dependency_injection.dart';
import '../../controllers/video_controller.dart';
import '../../models/video_calls_response.dart';
import '../../utils/app_logger.dart';
import 'schedule_video_call_dialog.dart';

class FamilyVideoCallsScreen extends StatefulWidget {
  const FamilyVideoCallsScreen({super.key});

  @override
  State<FamilyVideoCallsScreen> createState() => _FamilyVideoCallsScreenState();
}

class _FamilyVideoCallsScreenState extends State<FamilyVideoCallsScreen> {
  final VideoController _controller = Get.put(VideoController());
  List<Senior> _seniors = [];
  bool _loadingSeniors = true;

  @override
  void initState() {
    super.initState();
    _loadSeniors();
    _controller.fetchVideoCalls(isRefresh: true);
  }

  Future<void> _loadSeniors() async {
    try {
      final res = await locator<SeniorRepository>().getSeniors();
      if (mounted) {
        setState(() {
          _seniors = res.seniors;
          _loadingSeniors = false;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load seniors for mapping names', e);
      if (mounted) {
        setState(() {
          _loadingSeniors = false;
        });
      }
    }
  }

  String _getSeniorName(String seniorId) {
    for (final s in _seniors) {
      if (s.id == seniorId) return s.name;
    }
    return 'Senior Citizen';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year;
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    
    int hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    
    return '$day-$month-$year $hour:$minute $period';
  }

  Future<void> _joinCall(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid meeting URL'),
        backgroundColor: SevaColors.red,
      ));
      return;
    }

    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        AppLogger.i('Successfully launched meeting URL: $url');
      } else {
        AppLogger.e('Could not launch meeting URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to open meeting link'),
            backgroundColor: SevaColors.red,
          ));
        }
      }
    } catch (e, stack) {
      AppLogger.e('Exception launching meeting URL: $url', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: SevaColors.red,
        ));
      }
    }
  }

  Future<void> _endCall(BuildContext context, String callId) async {
    final success = await _controller.endCall(callId: callId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Call Ended Successfully'),
        backgroundColor: SevaColors.green,
        behavior: SnackBarBehavior.floating,
      ));
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
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Video Calls'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_seniors.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No seniors available to schedule call.'),
              backgroundColor: SevaColors.red,
            ));
            return;
          }
          showDialog(
            context: context,
            builder: (_) => ScheduleVideoCallDialog(preSelectedSenior: _seniors.first),
          );
        },
        icon: const Icon(Icons.add_call),
        label: const Text('New Call'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.fetchVideoCalls(isRefresh: true),
        color: SevaColors.primary,
        child: Obx(() {
          final state = _controller.state.value;
          final calls = _controller.videoCalls;

          if (state == VideoState.loading && calls.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: SevaColors.primary),
            );
          }

          if (state == VideoState.error && calls.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: SevaColors.red),
                    const SizedBox(height: 16),
                    Text(
                      _controller.errorMessage.value.isNotEmpty
                          ? _controller.errorMessage.value
                          : 'Failed to load video calls',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _controller.fetchVideoCalls(isRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (calls.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                const EmptyState(
                  icon: Icons.videocam_off_outlined,
                  title: 'No Video Calls Found',
                  subtitle: 'Schedule a call or make an instant video call now.',
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              final isCallActive = call.status.toLowerCase() == 'active';
              final isCallScheduled = call.status.toLowerCase() == 'scheduled';
              final seniorName = _getSeniorName(call.seniorId);

              return Card(
                elevation: isCallActive ? 2 : 0,
                shadowColor: isCallActive ? SevaColors.green.withValues(alpha: 0.3) : Colors.transparent,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isCallActive
                        ? SevaColors.green.withValues(alpha: 0.5)
                        : SevaColors.border,
                    width: isCallActive ? 2 : 1,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCallActive
                        ? SevaColors.greenLight.withValues(alpha: 0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Status tag, senior name)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seniorName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: SevaColors.textPrimary,
                                  ),
                                ),
                                if (call.caller != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'By: ${call.caller!.name} (${call.caller!.role.toUpperCase()})',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: SevaColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _buildStatusBadge(call.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: SevaColors.divider),
                      const SizedBox(height: 12),
                      // Time Info Row
                      Row(
                        children: [
                          Icon(
                            isCallScheduled ? Icons.calendar_today_outlined : Icons.access_time_outlined,
                            size: 16,
                            color: SevaColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isCallScheduled
                                  ? 'Scheduled: ${_formatDateTime(call.startedAt)}'
                                  : isCallActive
                                      ? 'Started: ${_formatDateTime(call.startedAt)}'
                                      : 'Ended: ${call.endedAt != null ? _formatDateTime(call.endedAt!) : _formatDateTime(call.startedAt)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: SevaColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Action Row (Join Call)
                      if (isCallActive || (isCallScheduled && call.meetUrl.isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (isCallActive) ...[
                              Expanded(
                                child: Obx(() => ElevatedButton.icon(
                                  onPressed: _controller.submitting.value
                                      ? null
                                      : () => _joinCall(call.meetUrl),
                                  icon: const Icon(Icons.videocam, size: 18),
                                  label: const Text('Join'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SevaColors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Obx(() => ElevatedButton.icon(
                                  onPressed: _controller.submitting.value
                                      ? null
                                      : () => _endCall(context, call.id),
                                  icon: _controller.submitting.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.call_end, size: 18),
                                  label: const Text('End Call'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SevaColors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )),
                              ),
                            ] else ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _joinCall(call.meetUrl),
                                  icon: const Icon(Icons.videocam, size: 18),
                                  label: const Text('Join Scheduled Call'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SevaColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = SevaColors.greenLight;
        textColor = SevaColors.green;
        break;
      case 'scheduled':
        bgColor = SevaColors.primaryLight;
        textColor = SevaColors.primary;
        break;
      default:
        bgColor = SevaColors.divider;
        textColor = SevaColors.textSecondary;
        text = 'COMPLETED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
