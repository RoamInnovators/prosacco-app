import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/prosacco_palette.dart';
import '../widgets/prosacco_auth_backdrop.dart';
import '../widgets/prosacco_trust_footer.dart';
import '../widgets/toast/toast_service.dart';
import '../widgets/toast/toast_variant.dart';
import 'member_reset_password_screen.dart';

/// Secure member login — layout from `prosacco design/login/code.html`.
class MemberSignInScreen extends StatefulWidget {
  const MemberSignInScreen({
    super.key,
    this.onLoginSubmitted,
    this.onBiometricLoginRequested,
  });

  /// Called after local validation; next step depends on backend response
  /// (`POST /member/login` when wired).
  final Future<void> Function(String memberIdentifier, String password)?
      onLoginSubmitted;
  final Future<void> Function()? onBiometricLoginRequested;

  @override
  State<MemberSignInScreen> createState() => _MemberSignInScreenState();
}

class _MemberSignInScreenState extends State<MemberSignInScreen> {
  final _memberIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _memberIdFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _submitting = false;
  bool _biometricChecking = true;
  bool _biometricAvailable = false;
  bool _biometricSubmitting = false;
  String? _errorMessage;

  static const String _spTokenKey = 'prosacco_member_token';
  static const String _spBiometricLoginEnabledKey =
      'prosacco_biometric_login_enabled';
  static const int _maxLoginAttempts = 5;
  int _attemptsRemaining = _maxLoginAttempts - 1; // matches old static hint: "4 remaining"
  DateTime? _lockedUntil;
  Timer? _lockTimer;

  static const double _maxFormWidth = 448;

  bool get _isLocked {
    final until = _lockedUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  String _formatLockRemaining() {
    final until = _lockedUntil;
    if (until == null) return '';
    final diff = until.difference(DateTime.now());
    final mins = diff.inMinutes.clamp(0, 999);
    final secs = diff.inSeconds % 60;
    final mm = mins.toString();
    final ss = secs.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void initState() {
    super.initState();
    _loadBiometricOption();
    if (_isLocked) {
      _lockTimer?.cancel();
      _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!_isLocked) {
          setState(() {
            _lockedUntil = null;
            _attemptsRemaining = _maxLoginAttempts - 1;
          });
          _lockTimer?.cancel();
          _lockTimer = null;
        } else {
          setState(() {});
        }
      });
    }
  }

  Future<void> _loadBiometricOption() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final hasSavedSession = (sp.getString(_spTokenKey) ?? '').isNotEmpty;
      final enabled = sp.getBool(_spBiometricLoginEnabledKey) ?? true;
      var available = false;
      if (hasSavedSession && enabled && widget.onBiometricLoginRequested != null) {
        final auth = LocalAuthentication();
        available = await auth.isDeviceSupported() && await auth.canCheckBiometrics;
      }
      if (!mounted) return;
      setState(() {
        _biometricAvailable = available;
        _biometricChecking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricAvailable = false;
        _biometricChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _memberIdController.dispose();
    _passwordController.dispose();
    _memberIdFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ToastService.of(context).show(
      variant: ToastVariant.error,
      message: message,
    );
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _registerFailedLoginAttempt() {
    if (_isLocked) return;
    final next = (_attemptsRemaining - 1).clamp(0, _maxLoginAttempts - 1);
    setState(() {
      _attemptsRemaining = next;
      if (next <= 0) {
        _lockedUntil = DateTime.now().add(const Duration(minutes: 30));
      }
    });

    _lockTimer?.cancel();
    if (_lockedUntil != null) {
      _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!_isLocked) {
          setState(() {
            _lockedUntil = null;
            _attemptsRemaining = _maxLoginAttempts - 1;
          });
          _lockTimer?.cancel();
          _lockTimer = null;
        } else {
          setState(() {});
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final id = _memberIdController.text.trim();
    final pass = _passwordController.text;
    if (id.isEmpty || pass.isEmpty) {
      _showError('Enter your email address and password.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(id)) {
      _showError('Enter a valid email address.');
      return;
    }

    if (_isLocked) {
      if (!mounted) return;
      ToastService.of(context).show(
        variant: ToastVariant.warning,
        message: 'Too many attempts. Locked for ${_formatLockRemaining()}.',
      );
      return;
    }

    setState(() => _submitting = true);
    setState(() => _errorMessage = null);
    try {
      await widget.onLoginSubmitted?.call(id, pass);
      if (!mounted) return;
      setState(() {
        _lockedUntil = null;
        _attemptsRemaining = _maxLoginAttempts - 1;
      });
    } catch (e) {
      final msg = e?.toString() ?? 'Login failed.';
      if (!mounted) return;
      final lower = msg.toLowerCase();
      final isInvalidPassword =
          lower.contains('invalid login') || lower.contains('invalid') && lower.contains('password');
      if (isInvalidPassword) {
        _registerFailedLoginAttempt();
      }
      _showError(msg);
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  Future<void> _submitBiometric() async {
    if (_biometricSubmitting || _submitting || _isLocked) return;
    final handler = widget.onBiometricLoginRequested;
    if (handler == null) return;
    setState(() {
      _biometricSubmitting = true;
      _errorMessage = null;
    });
    try {
      await handler();
    } catch (e) {
      if (!mounted) return;
      _showError(e?.toString() ?? 'Biometric login failed.');
    } finally {
      if (mounted) setState(() => _biometricSubmitting = false);
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxFormWidth),
                  child: Column(
                    children: [
                      _buildBrand(textTheme),
                      const SizedBox(height: 40),
                      _buildFormCard(textTheme),
                      const SizedBox(height: 32),
                      _buildFooter(textTheme),
                    ],
                  ),
                ),
              ),
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
            Icons.account_balance_rounded,
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
          'Secure Member Login',
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
          _buildLabel('Email Address'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _memberIdController,
            focusNode: _memberIdFocus,
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            obscure: false,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: _buildLabel('Password')),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (context) => const MemberResetPasswordScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.pal.secondary,
                    letterSpacing: 0.5,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            obscure: _obscurePassword,
            onChanged: (_) => _clearError(),
            suffix: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.pal.outline,
              ),
              splashRadius: 22,
            ),
          ),
          const SizedBox(height: 24),
          _buildSecurityHint(),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.pal.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: context.pal.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: context.pal.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.pal.onErrorContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: (_submitting || _isLocked) ? null : _submit,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _submitting ? 'Signing in…' : 'Log In',
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
          if (!_biometricChecking && _biometricAvailable) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: context.pal.outline.withValues(alpha: 0.18))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: textTheme.labelSmall?.copyWith(
                      color: context.pal.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.pal.outline.withValues(alpha: 0.18))),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: (_biometricSubmitting || _submitting || _isLocked)
                  ? null
                  : _submitBiometric,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(color: context.pal.primary.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                Icons.fingerprint_rounded,
                color: context.pal.primary,
              ),
              label: Text(
                _biometricSubmitting ? 'Checking biometrics…' : 'Log in with biometrics',
                style: textTheme.titleSmall?.copyWith(
                  color: context.pal.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required TextInputAction textInputAction,
    required void Function(String) onSubmitted,
    required bool obscure,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: TextStyle(
        color: context.pal.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
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
        contentPadding: EdgeInsets.fromLTRB(
          12,
          16,
          suffix != null ? 8 : 16,
          16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: context.pal.outline),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildSecurityHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pal.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.pal.error.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_rounded,
            color: context.pal.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Alert',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.pal.onErrorContainer,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLocked
                      ? 'Too many attempts. Locked for ${_formatLockRemaining()}.'
                      : '$_attemptsRemaining login attempts remaining. 5 failed attempts will trigger a 30-minute security lockout.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: context.pal.onErrorContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(TextTheme textTheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'New to ProSacco?',
              style: textTheme.bodyMedium?.copyWith(
                color: context.pal.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                // Self-register — `/member/register` when wired.
              },
              style: TextButton.styleFrom(
                foregroundColor: context.pal.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Self-Register',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.pal.secondary,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const ProsaccoTrustFooter(),
      ],
    );
  }
}
