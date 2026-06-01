import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';
import '../shared/senior_detail_screen.dart';
import '../../core/api/api_client.dart';
import '../../services/dependency_injection.dart';
import '../../utils/app_logger.dart';

class FamilySeniors extends StatefulWidget {
  const FamilySeniors({super.key});

  @override
  State<FamilySeniors> createState() => _FamilySeniorsState();
}

class _FamilySeniorsState extends State<FamilySeniors> {
  bool _loading = false;
  List<Senior> _seniors = [];
  String? _error;

  // Pagination metadata for future-proofing
  int _page = 1;
  int _limit = 20;
  int _total = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _fetchSeniors();
  }

  Future<void> _fetchSeniors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    AppLogger.i('Fetch seniors started');

    try {
      final result = await locator<ApiClient>().get('seniors');
      
      AppLogger.i('API response received');

      if (result.success && result.data != null) {
        final List<dynamic> dataList = result.data as List<dynamic>;
        final fetchedSeniors = dataList.map((e) => Senior.fromJson(e as Map<String, dynamic>)).toList();

        // Capture pagination metadata from result
        if (result.pagination != null) {
          final pagination = result.pagination!;
          _page = pagination['page'] as int? ?? 1;
          _limit = pagination['limit'] as int? ?? 20;
          _total = pagination['total'] as int? ?? 0;
          _totalPages = pagination['totalPages'] as int? ?? 0;
        }

        AppLogger.i('Seniors count loaded: ${fetchedSeniors.length} (Page: $_page/$_totalPages, Limit: $_limit, Total: $_total)');

        if (fetchedSeniors.isEmpty) {
          AppLogger.i('Empty list received');
        }

        if (mounted) {
          setState(() {
            _seniors = fetchedSeniors;
          });
        }
      } else {
        AppLogger.e('API error: ${result.errorMessage}');
        if (mounted) {
          setState(() {
            _error = result.errorMessage;
          });
        }
        _showErrorSnackbar(result.errorMessage);
      }
    } catch (e, stack) {
      AppLogger.e('API error', e, stack);
      String displayError = 'Something went wrong. Please try again.';
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        displayError = 'Unable to connect. Please check your internet connection.';
      }
      if (mounted) {
        setState(() {
          _error = displayError;
        });
      }
      _showErrorSnackbar(displayError);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: SevaColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('My Seniors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Contact support to add a new senior to your plan.'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchSeniors();
          AppLogger.i('Refresh completed');
        },
        color: SevaColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _seniors.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: SevaColors.primary),
      );
    }

    if (_error != null && _seniors.isEmpty) {
      return Center(
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
                onPressed: _fetchSeniors,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_seniors.isEmpty) {
      return Center(
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Contact support to add a new senior to your plan.'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Senior'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _seniors.length,
      itemBuilder: (context, i) {
        final s = _seniors[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SevaCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: s))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SevaAvatar(initials: s.avatar.isNotEmpty ? s.avatar : 'S', size: 52),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Age ${s.age} | ${s.gender} | ${s.mobility.isNotEmpty ? s.mobility : "Not specified"}',
                    style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                ])),
                StatusBadge(status: s.status),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: SevaColors.textTertiary),
                const SizedBox(width: 4),
                Text('${s.zone}, ${s.city}', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
                const Spacer(),
                const Icon(Icons.person_outline, size: 14, color: SevaColors.textTertiary),
                const SizedBox(width: 4),
                Text(s.careAide.isNotEmpty ? s.careAide : 'No care aide', style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary)),
              ]),
              const SizedBox(height: 12),
              // Mini vitals row
              Row(children: [
                _miniVital('BP', s.vitals['bp'] ?? 'N/A', SevaColors.primary),
                const SizedBox(width: 8),
                _miniVital('SpO2', s.vitals['spo2'] != null ? '${s.vitals['spo2']}%' : 'N/A', SevaColors.green),
                const SizedBox(width: 8),
                _miniVital('HR', s.vitals['heartRate']?.toString() ?? 'N/A', SevaColors.purple),
                const SizedBox(width: 8),
                _miniVital('Temp', s.vitals['temp'] != null ? '${s.vitals['temp']}°F' : 'N/A', SevaColors.orange),
              ]),
              if (s.conditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Conditions
                Wrap(spacing: 6, runSpacing: 6, children: s.conditions.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: SevaColors.redLight, borderRadius: BorderRadius.circular(6)),
                  child: Text(c, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: SevaColors.red)),
                )).toList()),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _miniVital(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Text('$label $value', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
