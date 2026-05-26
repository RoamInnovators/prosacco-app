import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';

class ProfileDevicesScreen extends StatefulWidget {
  const ProfileDevicesScreen({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  State<ProfileDevicesScreen> createState() => _ProfileDevicesScreenState();
}

class _ProfileDevicesScreenState extends State<ProfileDevicesScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _loadError;
  List<MemberDeviceData> _devices = const [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final list = await api.fetchMemberDevices(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _devices = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load devices.';
        _loading = false;
      });
    }
  }

  Future<void> _revokeDevice(String id) async {
    try {
      setState(() => _busy = true);
      final api = ProsaccoMemberAuthApi();
      await api.revokeMemberDevice(token: widget.authToken, deviceId: id);
      await _loadDevices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e?.toString() ?? 'Failed to revoke device.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_loading) {
      return Scaffold(
        backgroundColor: p.surface,
        appBar: AppBar(title: const Text('Active devices & sessions')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Active devices & sessions')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _loadError!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Text(
            'You are signed in on the devices below. Revoke any session you do not recognise.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          if (_devices.isEmpty)
            Text(
              'No active sessions found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.onSurfaceVariant,
                  ),
            )
          else
            ..._devices.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _deviceCard(
                  context,
                  title: d.device,
                  subtitle: '${d.os} · ${d.browser} · ${d.ip}',
                  current: d.current,
                  onRevoke: d.current || _busy ? null : () => _revokeDevice(d.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deviceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool current,
    required VoidCallback? onRevoke,
  }) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smartphone_rounded, color: p.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: p.onSurface,
                      ),
                ),
              ),
              if (current)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'THIS DEVICE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: p.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: p.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          if (!current)
            TextButton(
              onPressed: onRevoke,
              child: Text(
                'Revoke session',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: p.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
