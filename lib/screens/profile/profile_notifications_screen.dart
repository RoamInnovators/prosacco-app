import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState
    extends State<ProfileNotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<MemberNotificationData> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ProsaccoMemberAuthApi();
      final list = await api.fetchMemberNotifications(
          token: widget.authToken, limit: 50);
      if (!mounted) return;
      setState(() { _notifications = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markAllRead() async {
    try {
      final api = ProsaccoMemberAuthApi();
      await api.markAllNotificationsRead(token: widget.authToken);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _markRead(String id) async {
    try {
      final api = ProsaccoMemberAuthApi();
      await api.markNotificationAsRead(
          token: widget.authToken, notificationId: id);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx >= 0) {
          _notifications = List.from(_notifications)
            ..[idx] = MemberNotificationData(
              id: _notifications[idx].id,
              title: _notifications[idx].title,
              body: _notifications[idx].body,
              category: _notifications[idx].category,
              read: true,
              createdAt: _notifications[idx].createdAt,
            );
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (_loading) {
      return Scaffold(
        backgroundColor: p.surface,
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }

    final unread = _notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: TextStyle(
                      color: p.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.error)),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            : _notifications.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 56,
                                  color: p.outline.withValues(alpha: 0.4)),
                              const SizedBox(height: 16),
                              Text('No notifications yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: p.outline.withValues(alpha: 0.08)),
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      return _NotificationTile(
                        notification: n,
                        onTap: n.read ? null : () => _markRead(n.id),
                      );
                    },
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final MemberNotificationData notification;
  final VoidCallback? onTap;

  IconData _categoryIcon(String category) {
    return switch (category.toUpperCase()) {
      'LOAN' => Icons.payments_outlined,
      'ACCOUNT' => Icons.account_balance_outlined,
      'SECURITY' => Icons.security_outlined,
      'TRANSACTION' => Icons.swap_horiz_rounded,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final unread = !notification.read;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? p.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: unread
                    ? p.primary.withValues(alpha: 0.12)
                    : p.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(notification.category),
                size: 20,
                color: unread ? p.primary : p.outline,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: p.onSurface,
                              ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: p.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  if (notification.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notification.createdAt!),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: p.outline,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
