import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';

class ProfileChangePasswordScreen extends StatefulWidget {
  const ProfileChangePasswordScreen({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  State<ProfileChangePasswordScreen> createState() =>
      _ProfileChangePasswordScreenState();
}

class _ProfileChangePasswordScreenState
    extends State<ProfileChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Change password')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Use a strong password you do not reuse elsewhere.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          _pwdField(context, 'Current password', _current),
          const SizedBox(height: 16),
          _pwdField(context, 'New password', _next),
          const SizedBox(height: 16),
          _pwdField(context, 'Confirm new password', _confirm),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            label: Text(_obscure ? 'Show passwords' : 'Hide passwords'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_next.text.trim().length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New password must be at least 8 characters.')),
                      );
                      return;
                    }
                    if (_next.text != _confirm.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match.')),
                      );
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      final api = ProsaccoMemberAuthApi();
                      await api.changeMemberPassword(
                        token: widget.authToken,
                        currentPassword: _current.text,
                        newPassword: _next.text,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated.')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e?.toString() ?? 'Failed to update password.')),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: ThemeData.estimateBrightnessForColor(p.primary) ==
                      Brightness.dark
                  ? Colors.white
                  : const Color(0xFF022C22),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text('Update password', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _pwdField(
    BuildContext context,
    String label,
    TextEditingController c,
  ) {
    final p = context.pal;
    return TextField(
      controller: c,
      obscureText: _obscure,
      style: TextStyle(color: p.onSurface),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
