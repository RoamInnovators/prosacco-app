import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.authToken,
    required this.initialFullName,
    required this.initialPhone,
    required this.initialEmail,
  });

  final String authToken;
  final String initialFullName;
  final String initialPhone;
  final String initialEmail;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _otp;
  bool _saving = false;
  bool _sendingOtp = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialFullName);
    _phone = TextEditingController(text: widget.initialPhone);
    _email = TextEditingController(text: widget.initialEmail);
    _otp = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() => _sendingOtp = true);
    try {
      await ProsaccoMemberAuthApi().requestProfileOtp(
        token: widget.authToken,
        purpose: 'PROFILE_CHANGE',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent by SMS.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e?.toString() ?? 'Failed to send OTP.')),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Update how your name and contact details appear in the app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          _field(context, 'Full name', _name, readOnly: true),
          const SizedBox(height: 16),
          _field(context, 'Phone', _phone),
          const SizedBox(height: 16),
          _field(context, 'Email', _email),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _field(context, 'OTP approval code', _otp)),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _sendingOtp ? null : _requestOtp,
                child: Text(_sendingOtp ? 'Sending...' : 'Send OTP'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      final api = ProsaccoMemberAuthApi();
                      await api.patchMemberProfile(
                        token: widget.authToken,
                        phone: _phone.text.trim(),
                        email: _email.text.trim(),
                        otpCode: _otp.text.trim(),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile saved.')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e?.toString() ?? 'Failed to save profile.')),
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
                : const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController c, {
    bool readOnly = false,
  }) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: p.secondary,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          readOnly: readOnly,
          style: TextStyle(color: p.onSurface, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
