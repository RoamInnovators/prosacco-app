import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/prosacco_palette.dart';
import '../utils/otp_destination_hint.dart';
import '../widgets/prosacco_auth_backdrop.dart';
import '../widgets/prosacco_trust_footer.dart';
import '../widgets/toast/toast_service.dart';
import '../widgets/toast/toast_variant.dart';

/// Post-login OTP step — layout matches [MemberSignInScreen] / login mock.
class MemberOtpScreen extends StatefulWidget {
  const MemberOtpScreen({
    super.key,
    this.loginIdentifier,
    required this.onVerifyCode,
    required this.onResendCode,
    required this.onBackToSignIn,
  });

  /// Email, member number, etc. from the sign-in step (used for masked hint only).
  final String? loginIdentifier;

  final Future<void> Function(String code) onVerifyCode;
  final Future<void> Function() onResendCode;
  final VoidCallback onBackToSignIn;

  @override
  State<MemberOtpScreen> createState() => _MemberOtpScreenState();
}

class _MemberOtpScreenState extends State<MemberOtpScreen> {
  static const int _digits = 6;
  static const double _maxFormWidth = 448;

  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();
  bool _submitting = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _otpFocus.addListener(() => setState(() {}));
    _otpController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _setCaret(int index) {
    final len = _otpController.text.length;
    final off = (index <= len ? index : len).clamp(0, _digits);
    _otpController.selection = TextSelection.collapsed(offset: off);
    _otpFocus.requestFocus();
    setState(() {});
  }

  int _activeCellIndex(String code, int baseOffset) {
    final o = baseOffset.clamp(0, _digits);
    if (o < _digits) return o;
    return _digits - 1;
  }

  void _verify() {
    if (_submitting) return;
    if (_otpController.text.length != _digits) {
      ToastService.of(context).show(
        variant: ToastVariant.error,
        message: 'Enter the full 6-digit code.',
      );
      return;
    }
    final code = _otpController.text.trim();
    setState(() => _submitting = true);
    widget.onVerifyCode(code).catchError((e) {
      final msg = e?.toString() ?? 'Verification failed.';
      ToastService.of(context).show(
        variant: ToastVariant.error,
        message: msg,
      );
    }).whenComplete(() {
      if (!mounted) return;
      setState(() => _submitting = false);
    });
  }

  void _resend() {
    if (_resending) return;
    setState(() => _resending = true);
    widget.onResendCode().then((_) {
      ToastService.of(context).show(
        variant: ToastVariant.info,
        message: 'A new code has been sent.',
      );
    }).catchError((e) {
      final msg = e?.toString() ?? 'Could not resend code.';
      ToastService.of(context).show(
        variant: ToastVariant.error,
        message: msg,
      );
    }).whenComplete(() {
      if (!mounted) return;
      setState(() => _resending = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hint = otpDestinationHint(widget.loginIdentifier);

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
                        onPressed: widget.onBackToSignIn,
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: context.pal.primary,
                      ),
                      Expanded(
                        child: Text(
                          'Verification',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.pal.primary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Text(
                        'ProSacco',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.pal.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            _buildBrand(textTheme, hint),
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

  Widget _buildBrand(TextTheme textTheme, String hint) {
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
            Icons.sms_outlined,
            size: 48,
            color: context.pal.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Enter verification code',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: context.pal.onSurface,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to $hint.',
          style: textTheme.bodyMedium?.copyWith(
            color: context.pal.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
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
          Text(
            'ONE-TIME PASSCODE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: context.pal.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildOtpField(),
          const SizedBox(height: 20),
          Container(
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
                  Icons.timer_outlined,
                  color: context.pal.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Codes expire after a few minutes for your security. '
                    'Didn’t receive anything? Check spam or request a new code.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: context.pal.onSurfaceVariant
                          .withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resending ? null : _resend,
              style: TextButton.styleFrom(
                foregroundColor: context.pal.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _resending ? 'Resending…' : 'Resend code',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.pal.secondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submitting ? null : _verify,
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
                  _submitting ? 'Verifying…' : 'Verify & continue',
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

  Widget _buildOtpField() {
    final code = _otpController.text;
    final baseOffset = _otpController.selection.isValid
        ? _otpController.selection.baseOffset
        : code.length;
    final active = _otpFocus.hasFocus
        ? _activeCellIndex(code, baseOffset)
        : -1;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocus,
                maxLength: _digits,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: context.pal.onSurface,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _otpFocus.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_digits, (i) {
              final ch = i < code.length ? code[i] : '';
              final showActive = active == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 6,
                    right: i == _digits - 1 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: () => _setCaret(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.pal.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: showActive
                              ? context.pal.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          ch,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: context.pal.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(TextTheme textTheme) {
    return TextButton(
      onPressed: widget.onBackToSignIn,
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
