import 'package:flutter/material.dart';

import '../theme/prosacco_palette.dart';
import '../utils/prosacco_member_auth_api.dart';
import '../widgets/prosacco_auth_backdrop.dart';
import '../widgets/prosacco_trust_footer.dart';

/// Password reset request — visual system matches [MemberSignInScreen] / login mock.
class MemberResetPasswordScreen extends StatefulWidget {
  const MemberResetPasswordScreen({super.key});

  @override
  State<MemberResetPasswordScreen> createState() =>
      _MemberResetPasswordScreenState();
}

class _MemberResetPasswordScreenState extends State<MemberResetPasswordScreen> {
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _focus = FocusNode();
  String? _challengeId;
  String? _sentTo;
  bool _busy = false;

  static const double _maxFormWidth = 448;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _identifierController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email or member number to continue.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ProsaccoMemberAuthApi();
      if (_challengeId == null) {
        final challenge = await api.requestPasswordReset(login: id);
        if (!mounted) return;
        setState(() {
          _challengeId = challenge.challengeId;
          _sentTo = challenge.sentTo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset code sent${_sentTo == null ? '' : ' to $_sentTo'}.'),),
        );
        return;
      }

      final password = _passwordController.text.trim();
      if (_otpController.text.trim().length != 6 || password.length < 8) {
        throw 'Enter the 6-digit OTP and a password of at least 8 characters.';
      }
      await api.resetPassword(
        login: id,
        challengeId: _challengeId!,
        code: _otpController.text.trim(),
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully. Please sign in.')),
      );
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e?.toString() ?? 'Password reset failed.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.pal.surface,
      body: Stack(
        children: [
          const ProsaccoAuthBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: context.pal.primary,
                        style: IconButton.styleFrom(
                          foregroundColor: context.pal.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Reset password',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.pal.primary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: _maxFormWidth),
                        child: Column(
                          children: [
                            _buildBrand(textTheme),
                            const SizedBox(height: 32),
                            _buildFormCard(textTheme),
                            const SizedBox(height: 28),
                            _buildFooter(textTheme),
                            const SizedBox(height: 32),
                            const ProsaccoTrustFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand(TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.pal.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.pal.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            size: 48,
            color: context.pal.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ProSacco',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: context.pal.primary,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reset your password',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.pal.onSurfaceVariant,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.pal.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.pal.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel('Email or Member Number'),
          const SizedBox(height: 8),
          TextField(
            controller: _identifierController,
            focusNode: _focus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            autocorrect: false,
            style: TextStyle(
              color: context.pal.onSurface,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. MS-88291 or you@email.com',
              hintStyle: TextStyle(
                color: context.pal.outline.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: context.pal.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: context.pal.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: context.pal.outline,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          const SizedBox(height: 20),
          if (_challengeId != null) ...[
            _fieldLabel('OTP code'),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                hintText: '6-digit code',
                filled: true,
                fillColor: context.pal.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _fieldLabel('New password'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'At least 8 characters',
                filled: true,
                fillColor: context.pal.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          _infoHint(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: context.pal.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
              shadowColor: context.pal.primary.withValues(alpha: 0.2),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _challengeId == null ? 'Send reset code' : 'Reset password',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: context.pal.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _infoHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pal.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.pal.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: context.pal.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'For your security, we only send reset links or codes to the email or phone your SACCO already has on file. If you need help, contact your branch.',
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: context.pal.onSurfaceVariant.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(TextTheme textTheme) {
    return TextButton(
      onPressed: () => Navigator.maybePop(context),
      style: TextButton.styleFrom(
        foregroundColor: context.pal.secondary,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        'Back to sign in',
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.pal.secondary,
          decoration: TextDecoration.underline,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
