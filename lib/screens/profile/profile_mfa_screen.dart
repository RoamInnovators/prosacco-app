import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';

class ProfileMfaScreen extends StatefulWidget {
  const ProfileMfaScreen({super.key, required this.authToken});

  final String authToken;

  @override
  State<ProfileMfaScreen> createState() => _ProfileMfaScreenState();
}

class _ProfileMfaScreenState extends State<ProfileMfaScreen> {
  bool _loading = true;
  String? _error;
  MemberSecurityData? _security;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final security = await ProsaccoMemberAuthApi()
          .fetchMemberSecurity(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _security = security;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e?.toString() ?? 'Failed to load MFA settings.';
        _loading = false;
      });
    }
  }

  Future<void> _setup(String method) async {
    setState(() => _busy = true);
    try {
      final result = await ProsaccoMemberAuthApi().setupMemberMfa(
        token: widget.authToken,
        method: method,
      );
      if (!mounted) return;
      final codeCtrl = TextEditingController();
      bool? verified;
      String code = '';
      try {
        verified = await showDialog<bool>(
          context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(
            method == 'app' ? 'Authenticator setup' : 'SMS verification',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (method == 'app') ...[
                  if (result.manualEntry != null)
                    SelectableText(
                      'Manual key: ${result.manualEntry}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add this key to Google Authenticator or Microsoft Authenticator, then enter the 6-digit code.',
                  ),
                ] else
                  const Text(
                    'Enter the 6-digit code sent to your registered phone.',
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Verify'),
            ),
          ],
        ),
        );
        code = codeCtrl.text.trim();
      } finally {
        codeCtrl.dispose();
      }
      if (verified == true) {
        await ProsaccoMemberAuthApi().verifyMemberMfaSetup(
          token: widget.authToken,
          code: code,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Two-factor authentication enabled.')),
        );
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e?.toString() ?? 'MFA setup failed.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final passwordCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable MFA'),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    final password = passwordCtrl.text;
    passwordCtrl.dispose();
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await ProsaccoMemberAuthApi().disableMemberMfa(
        token: widget.authToken,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication disabled.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e?.toString() ?? 'Could not disable MFA.')),
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
        appBar: AppBar(title: const Text('Two-factor authentication')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }

    final enabled = _security?.mfaEnabled == true;
    final method = _security?.mfaMethod?.toUpperCase() ?? '';

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Two-factor authentication')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: p.error)),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  enabled ? Icons.verified_user_rounded : Icons.shield_outlined,
                  color: p.primary,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enabled ? 'MFA is enabled' : 'MFA is disabled',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: p.headlineGreen,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enabled
                            ? 'Method: ${method.isEmpty ? 'Configured' : method}'
                            : 'Protect sign-in with SMS or an authenticator app.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: p.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!enabled) ...[
            FilledButton.icon(
              onPressed: _busy ? null : () => _setup('sms'),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Enable SMS MFA'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _setup('app'),
              icon: const Icon(Icons.phonelink_lock_rounded),
              label: const Text('Enable authenticator app'),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _busy ? null : _disable,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Disable MFA'),
            ),
        ],
      ),
    );
  }
}
