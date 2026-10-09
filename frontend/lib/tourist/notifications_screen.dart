import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/historia_components.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F9F6),
      body: SafeArea(child: NotificationsContent(standalone: true)),
    );
  }
}

class NotificationsContent extends StatefulWidget {
  final bool standalone;
  final String roleLabel;

  const NotificationsContent({
    super.key,
    this.standalone = false,
    this.roleLabel = 'ACCOUNT',
  });

  @override
  State<NotificationsContent> createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<NotificationsContent> {
  static const Color background = Color(0xFFF5F9F6);
  static const Color primary = Color(0xFF176D4E);

  final NotificationService _service = NotificationService();

  StreamSubscription<AppNotification>? _liveSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  List<AppNotification> _notifications = [];
  int? _userId;
  bool _loading = true;
  bool _socketConnected = false;
  bool _markingAllRead = false;
  String? _error;

  int get _unreadCount =>
      _notifications.where((notification) => !notification.read).length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = context.read<AuthProvider>().user;
    final nextUserId = user?.id;

    if (nextUserId != null && nextUserId != _userId) {
      _userId = nextUserId;
      _start(nextUserId);
    } else if (nextUserId == null && _userId != null) {
      _userId = null;
      _service.disconnectLive();
      _notifications = [];
    } else if (nextUserId == null && _loading) {
      setState(() {
        _loading = false;
        _error = 'Please log in again and try once more.';
      });
    }
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    _connectionSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _start(int userId) async {
    await _liveSubscription?.cancel();
    await _connectionSubscription?.cancel();

    _liveSubscription = _service.liveNotifications.listen(_receiveLive);
    _connectionSubscription = _service.connectionStatus.listen((connected) {
      if (!mounted) {
        return;
      }

      setState(() {
        _socketConnected = connected;
      });
    });

    await _loadNotifications();
    await _service.connectLive(userId);
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final notifications = await _service.getMine();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = ApiService.instance.getErrorMessage(error);
      });
    }
  }

  void _receiveLive(AppNotification notification) {
    if (!mounted) {
      return;
    }

    setState(() {
      final existingIndex = _notifications.indexWhere(
        (item) => item.id == notification.id,
      );

      if (existingIndex >= 0) {
        _notifications[existingIndex] = notification;
      } else {
        _notifications.insert(0, notification);
      }
    });
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.read) {
      return;
    }

    setState(() {
      _notifications = _notifications
          .map(
            (item) =>
                item.id == notification.id ? item.copyWith(read: true) : item,
          )
          .toList();
    });

    try {
      final updated = await _service.markRead(notification.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map((item) => item.id == notification.id ? notification : item)
            .toList();
      });

      _showError(error);
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0 || _markingAllRead) {
      return;
    }

    final previous = _notifications;

    setState(() {
      _markingAllRead = true;
      _notifications = _notifications
          .map((notification) => notification.copyWith(read: true))
          .toList();
    });

    try {
      await _service.markAllRead();
    } catch (error) {
      if (mounted) {
        setState(() {
          _notifications = previous;
        });
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _markingAllRead = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, String?>(
      (auth) => auth.user?.role,
    );
    final roleCopy = _roleCopy(role);

    return Container(
      color: background,
      child: RefreshIndicator(
        color: primary,
        onRefresh: () => _loadNotifications(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          children: [
            _NotificationsHero(
              roleLabel: widget.roleLabel,
              standalone: widget.standalone,
              unreadCount: _unreadCount,
              socketConnected: _socketConnected,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NotificationSummary(
                    title: roleCopy.title,
                    subtitle: roleCopy.subtitle,
                    total: _notifications.length,
                    unread: _unreadCount,
                    socketConnected: _socketConnected,
                    onMarkAllRead: _unreadCount == 0 ? null : _markAllRead,
                    markingAllRead: _markingAllRead,
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const _NotificationLoading()
                  else if (_error != null)
                    _NotificationError(
                      message: _error!,
                      onRetry: _loadNotifications,
                    )
                  else if (_notifications.isEmpty)
                    _NotificationEmpty(roleCopy.emptyMessage)
                  else
                    _NotificationList(
                      notifications: _notifications,
                      onTap: _markRead,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ApiService.instance.getErrorMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
  }

  _RoleNotificationCopy _roleCopy(String? role) {
    switch (role) {
      case 'ADMIN':
        return const _RoleNotificationCopy(
          title: 'Admin alerts',
          subtitle: 'Guide applications, review changes, and admin updates.',
          emptyMessage: 'No admin alerts right now.',
        );

      case 'GUIDE':
        return const _RoleNotificationCopy(
          title: 'Guide alerts',
          subtitle: 'Application decisions, bookings, and payment updates.',
          emptyMessage: 'No guide alerts right now.',
        );

      case 'TOURIST':
      default:
        return const _RoleNotificationCopy(
          title: 'Travel alerts',
          subtitle: 'Bookings, guide updates, and account messages.',
          emptyMessage: 'No travel alerts right now.',
        );
    }
  }
}

class _RoleNotificationCopy {
  final String title;
  final String subtitle;
  final String emptyMessage;

  const _RoleNotificationCopy({
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
  });
}

class _NotificationsHero extends StatelessWidget {
  final String roleLabel;
  final bool standalone;
  final int unreadCount;
  final bool socketConnected;

  const _NotificationsHero({
    required this.roleLabel,
    required this.standalone,
    required this.unreadCount,
    required this.socketConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9FCFA), Color(0xFFE8F4EC), Color(0xFFD8EBDD)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -58,
            child: Container(
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF176D4E).withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HistoriaLogoMark(size: 35),
                  const SizedBox(width: 9),
                  const Expanded(child: HistoriaBrandText()),
                  if (standalone)
                    HistoriaIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  _StatusPill(
                    text: '$roleLabel / NOTIFICATIONS',
                    color: const Color(0xFF347258),
                    background: Colors.white.withValues(alpha: 0.70),
                    border: const Color(0xFFD2E6DA),
                  ),
                  const SizedBox(width: 7),
                  _StatusPill(
                    text: socketConnected ? 'LIVE' : 'SYNC',
                    color: socketConnected
                        ? const Color(0xFF176D4E)
                        : const Color(0xFF94681C),
                    background: socketConnected
                        ? const Color(0xFFE5F2E9)
                        : const Color(0xFFFFF5DE),
                    border: socketConnected
                        ? const Color(0xFFC8E2D2)
                        : const Color(0xFFF0DDAA),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Color(0xFF143C2F),
                            fontSize: 27,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Your account updates in one place.',
                          style: TextStyle(
                            color: Color(0xFF6C8176),
                            fontSize: 10.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NotificationBell(unreadCount: unreadCount),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final Color border;

  const _StatusPill({
    required this.text,
    required this.color,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;

  const _NotificationBell({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCFE4D7)),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 29,
            color: Color(0xFF176D4E),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE04942),
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  final String title;
  final String subtitle;
  final int total;
  final int unread;
  final bool socketConnected;
  final VoidCallback? onMarkAllRead;
  final bool markingAllRead;

  const _NotificationSummary({
    required this.title,
    required this.subtitle,
    required this.total,
    required this.unread,
    required this.socketConnected,
    required this.onMarkAllRead,
    required this.markingAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE8E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09083A2A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F2E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  socketConnected
                      ? Icons.notifications_active_outlined
                      : Icons.sync_rounded,
                  size: 21,
                  color: const Color(0xFF176D4E),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF173E31),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF74857C),
                        fontSize: 8.8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _UnreadCounter(unread: unread),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: '$total',
                  label: total == 1 ? 'TOTAL ALERT' : 'TOTAL ALERTS',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryMetric(
                  value: '$unread',
                  label: unread == 1 ? 'UNREAD ALERT' : 'UNREAD ALERTS',
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  onPressed: onMarkAllRead,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF176D4E),
                    disabledBackgroundColor: const Color(0xFFDDE8E1),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF78887F),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: markingAllRead
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text(
                    'Read all',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnreadCounter extends StatelessWidget {
  final int unread;

  const _UnreadCounter({required this.unread});

  @override
  Widget build(BuildContext context) {
    final active = unread > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFECEA) : const Color(0xFFE9F4ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFFF1C3BF) : const Color(0xFFCFE3D7),
        ),
      ),
      child: Text(
        active ? '$unread NEW' : 'CLEAR',
        style: TextStyle(
          color: active ? const Color(0xFFB94B43) : const Color(0xFF247255),
          fontSize: 7,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E7DE)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF176D4E),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF718279),
                fontSize: 6.5,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;
  final ValueChanged<AppNotification> onTap;

  const _NotificationList({required this.notifications, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final notification in notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationTile(
              notification: notification,
              onTap: () => onTap(notification),
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _NotificationPalette.fromType(notification.type);
    final unread = !notification.read;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: unread ? palette.border : const Color(0xFFDDE8E1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08083A29),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(palette.icon, color: palette.main, size: 21),
                ),
                if (unread)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE04942),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF143C2F),
                            fontSize: 12.2,
                            height: 1.25,
                            fontWeight: unread
                                ? FontWeight.w900
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF87958F),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF6C7F75),
                      fontSize: 9.2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _TypeBadge(label: _typeLabel(notification.type)),
                      if (notification.referenceType != null) ...[
                        const SizedBox(width: 6),
                        _TypeBadge(label: notification.referenceType!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    final date = value.toLocal();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'now';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${date.month}/${date.day}';
  }

  String _typeLabel(String type) {
    return type.replaceAll('_', ' ');
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;

  const _TypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F7F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE8E1)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF547667),
            fontSize: 6.8,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NotificationLoading extends StatelessWidget {
  const _NotificationLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 54),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF176D4E))),
    );
  }
}

class _NotificationError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NotificationError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6D5D2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 44,
            color: Color(0xFFB94B43),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load notifications',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF143C2F),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF71847A),
              fontSize: 9,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF176D4E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  final String message;

  const _NotificationEmpty(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE8E1)),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F3EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 38,
              color: Color(0xFF176D4E),
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'No notifications yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF143C2F),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF71847A),
              fontSize: 9.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPalette {
  final Color main;
  final Color soft;
  final Color border;
  final IconData icon;

  const _NotificationPalette({
    required this.main,
    required this.soft,
    required this.border,
    required this.icon,
  });

  factory _NotificationPalette.fromType(String type) {
    if (type.contains('PAYMENT')) {
      return const _NotificationPalette(
        main: Color(0xFF176D4E),
        soft: Color(0xFFE4F3E9),
        border: Color(0xFFC6E1D1),
        icon: Icons.payments_outlined,
      );
    }

    if (type.contains('BOOKING')) {
      return const _NotificationPalette(
        main: Color(0xFF2B6E95),
        soft: Color(0xFFE3F1F8),
        border: Color(0xFFBFDCEA),
        icon: Icons.event_available_outlined,
      );
    }

    if (type.contains('GUIDE')) {
      return const _NotificationPalette(
        main: Color(0xFF8B6818),
        soft: Color(0xFFFFF5DB),
        border: Color(0xFFEEDCAC),
        icon: Icons.badge_outlined,
      );
    }

    return const _NotificationPalette(
      main: Color(0xFF176D4E),
      soft: Color(0xFFE5F2E9),
      border: Color(0xFFCFE3D7),
      icon: Icons.notifications_none_rounded,
    );
  }
}
