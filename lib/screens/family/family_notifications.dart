import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../services/dependency_injection.dart';
import '../../repositories/notification_repository.dart';
import '../../models/notification_model.dart';
import '../../utils/app_logger.dart';
import '../../services/websocket_service.dart';

class FamilyNotifications extends StatefulWidget {
  const FamilyNotifications({super.key});

  @override
  State<FamilyNotifications> createState() => _FamilyNotificationsState();
}

class _FamilyNotificationsState extends State<FamilyNotifications> {
  final _notificationRepo = locator<NotificationRepository>();
  
  List<NotificationModel> _notifications = [];
  String _filter = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _unreadCount = 0;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _markingRead = false;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _wsSubscription1;
  StreamSubscription? _wsSubscription2;
  StreamSubscription? _wsSubscription3;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchNotifications(page: 1);
    _setupWebSocketListeners();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _wsSubscription1?.cancel();
    _wsSubscription2?.cancel();
    _wsSubscription3?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  void _setupWebSocketListeners() {
    final ws = locator<WebSocketService>();
    
    // Silence refresh on new and updated alert (SOS events) & careLog changes
    _wsSubscription1 = ws.onNewAlert.listen((_) => _onWebSocketNotificationTrigger('SOS events'));
    _wsSubscription2 = ws.onAlertUpdate.listen((_) => _onWebSocketNotificationTrigger('SOS events'));
    _wsSubscription3 = ws.onCareLogUpdate.listen((_) => _onWebSocketNotificationTrigger('Care log updates'));
  }

  void _onWebSocketNotificationTrigger(String eventType) {
    AppLogger.i('WebSocket refresh triggered by $eventType');
    _fetchNotifications(page: 1, isRefresh: true);
  }

  Future<void> _fetchNotifications({required int page, bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _errorMessage = null;
      });
    } else if (page == 1) {
      setState(() {
        _initialLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await _notificationRepo.getNotifications(page: page, limit: 20);
      
      if (mounted) {
        setState(() {
          if (page == 1) {
            _notifications = res.notifications;
          } else {
            // Avoid duplicate items
            final existingIds = _notifications.map((n) => n.id).toSet();
            final newItems = res.notifications.where((n) => !existingIds.contains(n.id)).toList();
            _notifications.addAll(newItems);
          }
          
          // Sorting: newest notifications first
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _unreadCount = res.unreadCount;
          _currentPage = res.pagination.page;
          _totalPages = res.pagination.totalPages;
          _initialLoading = false;
          _loadingMore = false;
        });
      }
    } catch (e, stack) {
      AppLogger.e('API failures (UI)', e, stack);
      if (mounted) {
        setState(() {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('socketexception') ||
              errStr.contains('timeoutexception') ||
              errStr.contains('network') ||
              errStr.contains('connect') ||
              errStr.contains('internet')) {
            _errorMessage = 'Unable to load notifications';
          } else {
            _errorMessage = 'Something went wrong';
          }
          _initialLoading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_loadingMore || _initialLoading || _currentPage >= _totalPages) return;

    setState(() {
      _loadingMore = true;
    });

    AppLogger.i('Pagination triggered');
    await _fetchNotifications(page: _currentPage + 1);
  }

  Future<void> _markAsRead(List<String> ids) async {
    if (ids.isEmpty || _markingRead) return;

    // Keep deep copy of current state to revert if API fails
    final previousNotifications = _notifications.map((n) => NotificationModel(
      id: n.id,
      title: n.title,
      message: n.message,
      type: n.type,
      isRead: n.isRead,
      createdAt: n.createdAt,
    )).toList();
    final previousUnreadCount = _unreadCount;

    // Optimistically update UI local states instantly
    setState(() {
      _markingRead = true;
      _notifications = _notifications.map((n) {
        if (ids.contains(n.id)) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      final localUnreadCount = _notifications.where((n) => !n.isRead).length;
      _unreadCount = localUnreadCount;
      NotificationRepository.unreadCountNotifier.value = localUnreadCount;
    });

    AppLogger.i('Mark read request started (UI)');
    AppLogger.i('IDs sent (UI): $ids');

    try {
      final updatedUnreadCount = await _notificationRepo.markNotificationsAsRead(ids);
      
      if (mounted) {
        setState(() {
          _markingRead = false;
          _unreadCount = updatedUnreadCount;
        });
      }
    } catch (e, stack) {
      AppLogger.e('Request failure (UI)', e, stack);
      
      // Revert optimistic updates
      if (mounted) {
        setState(() {
          _notifications = previousNotifications;
          _unreadCount = previousUnreadCount;
          NotificationRepository.unreadCountNotifier.value = previousUnreadCount;
          _markingRead = false;
        });

        final errStr = e.toString().toLowerCase();
        String displayErr = 'Something went wrong';
        if (errStr.contains('socketexception') ||
            errStr.contains('timeoutexception') ||
            errStr.contains('network') ||
            errStr.contains('connect') ||
            errStr.contains('internet')) {
          displayErr = 'Unable to mark notification as read';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayErr),
            backgroundColor: SevaColors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _markAsRead(ids),
            ),
          ),
        );
      }
    }
  }

  // Track currently deleting IDs to prevent duplicate calls
  final Set<String> _deletingIds = {};

  Future<void> _deleteNotification(NotificationModel item, int originalIndex) async {
    final notificationId = item.id;
    if (_deletingIds.contains(notificationId)) return;

    _deletingIds.add(notificationId);
    
    // Save state for rollback if API call fails
    final wasRead = item.isRead;
    final previousUnreadCount = _unreadCount;

    // Optimistically update UI
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
      if (!wasRead) {
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        NotificationRepository.unreadCountNotifier.value = _unreadCount;
      }
    });

    AppLogger.i('Notification delete request started (UI)');
    AppLogger.i('ID to delete (UI): $notificationId');

    try {
      final success = await _notificationRepo.deleteNotification(notificationId);
      _deletingIds.remove(notificationId);
      if (!success) {
        throw Exception("API returned false success status");
      }
    } catch (e, stack) {
      AppLogger.e('Notification delete request failure (UI)', e, stack);
      _deletingIds.remove(notificationId);

      // Revert optimistic updates
      if (mounted) {
        setState(() {
          _notifications.insert(originalIndex, item);
          // Recalculate sorting to ensure it remains in place
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _unreadCount = previousUnreadCount;
          NotificationRepository.unreadCountNotifier.value = previousUnreadCount;
        });

        final errStr = e.toString().toLowerCase();
        String displayErr = 'Something went wrong';
        if (errStr.contains('socketexception') ||
            errStr.contains('timeoutexception') ||
            errStr.contains('network') ||
            errStr.contains('connect') ||
            errStr.contains('internet')) {
          displayErr = 'Unable to delete notification';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayErr),
            backgroundColor: SevaColors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _deleteNotification(item, originalIndex),
            ),
          ),
        );
      }
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
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
    switch (type.toLowerCase()) {
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
    switch (type.toLowerCase()) {
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
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<NotificationModel> get _filtered {
    if (_filter == 'all') return _notifications;
    if (_filter == 'unread') return _notifications.where((n) => !n.isRead).toList();
    return _notifications.where((n) => n.type.toLowerCase() == _filter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading && _notifications.isEmpty) {
      return Scaffold(
        backgroundColor: SevaColors.background,
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: CircularProgressIndicator(color: SevaColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return Scaffold(
        backgroundColor: SevaColors.background,
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: SevaColors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _fetchNotifications(page: 1),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: Text(_unreadCount > 0 ? 'Notifications ($_unreadCount)' : 'Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () {
                final unreadIds = _notifications.where((n) => !n.isRead).map((n) => n.id).toList();
                if (unreadIds.isNotEmpty) {
                  _markAsRead(unreadIds);
                }
              },
              child: Text('Mark all read', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.primary)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchNotifications(page: 1, isRefresh: true),
        color: SevaColors.primary,
        child: Column(children: [
          // Filter chips
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('all', 'All'),
                _filterChip('unread', 'Unread ($_unreadCount)'),
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
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    const EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'No Notifications Yet',
                      subtitle: "You'll see important updates here.",
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _filtered.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(color: SevaColors.primary, strokeWidth: 2),
                        ),
                      );
                    }

                    final n = _filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: SevaColors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return !_deletingIds.contains(n.id);
                        },
                        onDismissed: (direction) {
                          // Find absolute index of item in _notifications list before removing
                          final originalIndex = _notifications.indexWhere((item) => item.id == n.id);
                          if (originalIndex != -1) {
                            _deleteNotification(n, originalIndex);
                          }
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (!n.isRead) {
                              AppLogger.i('Notification tapped');
                              _markAsRead([n.id]);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: n.isRead ? Colors.white : SevaColors.primaryLight.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: n.isRead ? SevaColors.border : SevaColors.primary.withValues(alpha: 0.2)),
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
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                      color: SevaColors.textPrimary))),
                                  Text(_timeAgo(n.createdAt), style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                                ]),
                                const SizedBox(height: 4),
                                Text(n.message, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textSecondary, height: 1.4)),
                              ])),
                              if (!n.isRead) ...[
                                const SizedBox(width: 8),
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: SevaColors.primary, shape: BoxShape.circle)),
                              ],
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ]),
      ),
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
