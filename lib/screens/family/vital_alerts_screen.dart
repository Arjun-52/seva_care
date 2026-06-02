import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../services/dependency_injection.dart';
import '../../repositories/senior_repository.dart';
import '../../models/vital_alert_model.dart';
import '../../utils/app_logger.dart';

class VitalAlertsScreen extends StatefulWidget {
  const VitalAlertsScreen({super.key});

  @override
  State<VitalAlertsScreen> createState() => _VitalAlertsScreenState();
}

class _VitalAlertsScreenState extends State<VitalAlertsScreen> {
  final _seniorRepo = locator<SeniorRepository>();
  
  List<VitalAlertModel> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final alerts = await _seniorRepo.getVitalAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('Failed to fetch vital alerts', e, stack);
      if (mounted) {
        setState(() {
          final errStr = e.toString().replaceFirst('Exception: ', '');
          if (errStr.contains('SocketException') || 
              errStr.contains('TimeoutException') || 
              errStr.contains('network') || 
              errStr.contains('connect')) {
            _errorMessage = 'Network failure. Please check your internet connection and try again.';
          } else {
            _errorMessage = errStr;
          }
          _isLoading = false;
        });
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return SevaColors.red;
      case 'elevated':
        return SevaColors.saffron;
      default:
        return SevaColors.teal;
    }
  }

  Color _getSeverityBgColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return SevaColors.redLight;
      case 'elevated':
        return SevaColors.saffronLight;
      default:
        return SevaColors.tealLight;
    }
  }

  String _formatDateTime(DateTime dt) {
    // Return a simple friendly format e.g. "Jun 2, 2026 at 4:55 PM"
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Vital Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAlerts,
        color: SevaColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: SevaColors.primary),
            SizedBox(height: 16),
            Text('Loading vital alerts...', style: TextStyle(color: SevaColors.textSecondary)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SevaColors.redLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: SevaColors.red, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to Load Alerts',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SevaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: SevaColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchAlerts,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SevaColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: SevaColors.tealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: SevaColors.teal,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No active vital alerts',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SevaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything looks healthy! Any updates or alerts regarding your senior\'s health vitals will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: SevaColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pull down to refresh and check for updates.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: SevaColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        final severityColor = _getSeverityColor(alert.severity);
        final severityBg = _getSeverityBgColor(alert.severity);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SevaColors.borderLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: SevaColors.primary.withAlpha(6),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with severity badge
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: severityBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: severityColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title.isNotEmpty ? alert.title : alert.alertType,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: SevaColors.textPrimary,
                              ),
                            ),
                            if (alert.seniorName != null && alert.seniorName!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                alert.seniorName!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SevaColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: severityBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert.severity.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: severityColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: SevaColors.divider),

                // Content Message
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    alert.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: SevaColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),

                // Footer Timestamp
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: SevaColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(alert.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SevaColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
