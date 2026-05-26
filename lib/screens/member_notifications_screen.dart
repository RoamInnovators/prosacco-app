import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';
import '../utils/prosacco_member_auth_api.dart';
import '../widgets/prosacco_animated_loader.dart';

class MemberNotificationsScreen extends StatefulWidget {
  const MemberNotificationsScreen({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  State<MemberNotificationsScreen> createState() => _MemberNotificationsScreenState();
}

class _MemberNotificationsScreenState extends State<MemberNotificationsScreen> {
  bool _loading = true;
  bool _markingAll = false;
  String? _error;
  List<MemberNotificationData> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final api = ProsaccoMemberAuthApi();
      final items = await api.fetchMemberNotifications(token: widget.authToken, limit: 80);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e?.toString() ?? 'Failed to load notifications.';
        _loading = false;
      });
    }
  }

  Future<void> _openAndMark(MemberNotificationData item) async {
    if (!item.read) {
      try {
        final api = ProsaccoMemberAuthApi();
        await api.markNotificationAsRead(
          token: widget.authToken,
          notificationId: item.id,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _NotificationDetailScreen(item: item),
      ),
    );
    await _load();
  }

  Future<void> _markAllAsRead() async {
    if (_markingAll) return;
    try {
      setState(() => _markingAll = true);
      final api = ProsaccoMemberAuthApi();
      await api.markAllNotificationsRead(token: widget.authToken);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e?.toString() ?? 'Failed to mark all as read.')),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: (_items.any((n) => !n.read) && !_markingAll) ? _markAllAsRead : null,
            child: _markingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mark all as read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: ProsaccoAnimatedLoader(size: 110))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'No notifications yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: p.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    ..._items.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: n.read ? p.surfaceContainerLow : p.secondaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openAndMark(n),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: n.read ? p.outline : p.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: p.onSurface,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: p.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right_rounded, color: p.outline),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _NotificationDetailScreen extends StatelessWidget {
  const _NotificationDetailScreen({required this.item});

  final MemberNotificationData item;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Notification detail')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: p.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            item.category.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            item.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

