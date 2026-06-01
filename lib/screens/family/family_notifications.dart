import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../models/mock_data.dart';

class FamilyNotifications extends StatefulWidget {
  const FamilyNotifications({super.key});

  @override
  State<FamilyNotifications> createState() => _FamilyNotificationsState();
}

class _FamilyNotificationsState extends State<FamilyNotifications> {
  late List<SevaNotification> _notifications;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _notifications = List.from(MockData.notifications);
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'vitals': return Icons.monitor_heart;
      case 'care': return Icons.volunteer_activism;
      case 'medicine': return Icons.medication;
      case 'emergency': return Icons.emergency;
      case 'report': return Icons.assessment;
      case 'iot': return Icons.sensors;
      case 'payment': return Icons.payment;
      default: return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'vitals': return SevaColors.primary;
      case 'care': return SevaColors.teal;
      case 'medicine': return SevaColors.purple;
      case 'emergency': return SevaColors.red;
      case 'report': return SevaColors.amber;
      case 'iot': return SevaColors.orange;
      case 'payment': return SevaColors.green;
      default: return SevaColors.textSecondary;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'vitals': return SevaColors.primaryLight;
      case 'care': return SevaColors.tealLight;
      case 'medicine': return SevaColors.purpleLight;
      case 'emergency': return SevaColors.redLight;
      case 'report': return SevaColors.amberLight;
      case 'iot': return SevaColors.orangeLight;
      case 'payment': return SevaColors.greenLight;
      default: return SevaColors.divider;
    }
  }

  String _timeAgo(DateTime time) {
    final now = DateTime(2025, 5, 20, 14, 0);
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<SevaNotification> get _filtered {
    if (_filter == 'all') return _notifications;
    if (_filter == 'unread') return _notifications.where((n) => !n.read).toList();
    return _notifications.where((n) => n.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _notifications = _notifications.map((n) => SevaNotification(
                    id: n.id, title: n.title, body: n.body, type: n.type, time: n.time, read: true,
                  )).toList();
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('All notifications marked as read'),
                  behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                ));
              },
              child: Text('Mark all read', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.primary)),
            ),
        ],
      ),
      body: Column(children: [
        // Filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('all', 'All'),
              _filterChip('unread', 'Unread ($unreadCount)'),
              _filterChip('vitals', 'Vitals'),
              _filterChip('care', 'Care'),
              _filterChip('emergency', 'Emergency'),
              _filterChip('medicine', 'Medicine'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List
        Expanded(
          child: _filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.notifications_off_outlined, size: 56, color: SevaColors.textTertiary),
                const SizedBox(height: 12),
                Text('No notifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final n = _filtered[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          final idx = _notifications.indexWhere((x) => x.id == n.id);
                          if (idx >= 0) {
                            _notifications[idx] = SevaNotification(
                              id: n.id, title: n.title, body: n.body, type: n.type, time: n.time, read: true,
                            );
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: n.read ? Colors.white : SevaColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: n.read ? SevaColors.border : SevaColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: _typeBg(n.type), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_typeIcon(n.type), size: 22, color: _typeColor(n.type)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(n.title,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                                  color: SevaColors.textPrimary))),
                              Text(_timeAgo(n.time), style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                            ]),
                            const SizedBox(height: 4),
                            Text(n.body, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary, height: 1.4)),
                          ])),
                          if (!n.read) ...[
                            const SizedBox(width: 8),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: SevaColors.primary, shape: BoxShape.circle)),
                          ],
                        ]),
                      ),
                    ),
                  );
                },
              ),
        ),
      ]),
    );
  }

  Widget _filterChip(String value, String label) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? SevaColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: active ? null : Border.all(color: SevaColors.border),
          ),
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : SevaColors.textSecondary)),
        ),
      ),
    );
  }
}
