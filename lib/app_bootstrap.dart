import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/push_notifications_service.dart';
import 'screens/launch_screen.dart';
import 'screens/member_home_screen.dart';
import 'screens/member_otp_screen.dart';
import 'screens/member_sign_in_screen.dart';
import 'utils/balance_visibility.dart';
import 'utils/prosacco_member_auth_api.dart';
import 'widgets/toast/toast_service.dart';
import 'widgets/toast/toast_variant.dart';

enum _AppPhase { launch, signIn, otp, home }

/// Launch → sign-in → OTP → member dashboard.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  _AppPhase _phase = _AppPhase.launch;
  String? _loginIdentifier;
  String _homeDisplayName = 'Member';
  String? _authToken;
  String? _mfaToken;
  String? _deviceBindingToken;
  String? _deviceBindingChallengeId;
  bool _sessionLoaded = false;
  BalanceVisibilityController? _balanceVisibility;

  static const String _spTokenKey = 'prosacco_member_token';
  static const String _spDisplayNameKey = 'prosacco_member_display_name';
  static const String _privacyConsentVersion = '2026-04-01';
  static const String _spPrivacyConsentKey = 'prosacco_privacy_consent_version';

  Future<void> _loadSavedSession() async {
    if (_sessionLoaded) return;
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(_spTokenKey);
    final displayName = sp.getString(_spDisplayNameKey);
    if (!mounted) return;
    setState(() {
      _authToken = (token ?? '').isNotEmpty ? token : null;
      if (displayName != null && displayName.isNotEmpty) {
        _homeDisplayName = displayName;
      }
      _sessionLoaded = true;
    });
    PushNotificationsService.setAuthToken(_authToken);
  }

  Future<void> _persistSession({required String token, required String displayName}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_spTokenKey, token);
    await sp.setString(_spDisplayNameKey, displayName);
    _sessionLoaded = true;
    PushNotificationsService.setAuthToken(token);
  }

  Future<void> _clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_spTokenKey);
    await sp.remove(_spDisplayNameKey);
    PushNotificationsService.setAuthToken(null);
  }

  Future<void> _handleLaunchComplete() async {
    if (!_sessionLoaded) {
      await _loadSavedSession();
    }
    if (!mounted) return;
    final hasToken = (_authToken ?? '').isNotEmpty;
    if (hasToken && !await _requireBiometricIfAvailable()) {
      await _clearSession();
      _authToken = null;
      if (!mounted) return;
      setState(() => _phase = _AppPhase.signIn);
      return;
    }
    if (hasToken && !await _ensurePrivacyConsent(_authToken!)) {
      await _clearSession();
      _authToken = null;
      if (!mounted) return;
      setState(() => _phase = _AppPhase.signIn);
      return;
    }
    setState(() => _phase = hasToken ? _AppPhase.home : _AppPhase.signIn);
  }

  void _setHomeDisplayNameFromIdentifier(String? id) {
    if (id == null || id.isEmpty) {
      _homeDisplayName = 'Member';
      return;
    }
    final t = id.trim();
    if (t.contains('@')) {
      final local = t.split('@').first;
      if (local.isEmpty) {
        _homeDisplayName = 'Member';
        return;
      }
      _homeDisplayName =
          '${local[0].toUpperCase()}${local.substring(1).toLowerCase()}';
    } else {
      _homeDisplayName = t;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
    BalanceVisibilityController.load().then((controller) {
      if (!mounted) return;
      setState(() => _balanceVisibility = controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (_phase) {
        _AppPhase.launch => LaunchScreen(
            key: const ValueKey('splash'),
            onComplete: () => _handleLaunchComplete(),
          ),
        _AppPhase.signIn => MemberSignInScreen(
            key: const ValueKey('signin'),
            onLoginSubmitted: (id, password) => _handleLoginSubmitted(id, password),
          ),
        _AppPhase.otp => MemberOtpScreen(
            key: const ValueKey('otp'),
            loginIdentifier: _loginIdentifier,
            onVerifyCode: (code) => _handleVerifyMfa(code),
            onResendCode: () => _handleResendOtp(),
            onBackToSignIn: () {
              if (mounted) {
                setState(() {
                  _loginIdentifier = null;
                  _mfaToken = null;
                  _deviceBindingToken = null;
                  _deviceBindingChallengeId = null;
                  _phase = _AppPhase.signIn;
                });
              }
            },
          ),
        _AppPhase.home => _balanceVisibility == null
            ? const Center(
                key: ValueKey('home-loading'),
                child: CircularProgressIndicator(),
              )
            : BalanceVisibilityScope(
                key: const ValueKey('home'),
                controller: _balanceVisibility!,
                child: MemberHomeScreen(
                  displayName: _homeDisplayName,
                  authToken: _authToken ?? '',
                  onSignedOut: () {
                    _clearSession();
                    _authToken = null;
                    _mfaToken = null;
                    _deviceBindingToken = null;
                    _deviceBindingChallengeId = null;
                    _loginIdentifier = null;
                    _homeDisplayName = 'Member';
                    if (mounted) setState(() => _phase = _AppPhase.signIn);
                  },
                ),
              ),
      },
    );
  }

  void _enqueueWelcomeSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (message.isEmpty) return;
      ToastService.of(context).show(
        variant: ToastVariant.success,
        message: message,
      );
    });
  }

  Future<bool> _requireBiometricIfAvailable() async {
    final auth = LocalAuthentication();
    try {
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      if (!supported || !canCheck) return true;
      return auth.authenticate(
        localizedReason: 'Confirm it is you to access your ProSacco account.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return true;
    }
  }

  Future<bool> _ensurePrivacyConsent(String token) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getString(_spPrivacyConsentKey) == _privacyConsentVersion) return true;
    if (!mounted) return false;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy consent'),
        content: const Text(
          'Accept processing of your personal data for member portal services, security, fraud prevention, and regulatory compliance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (accepted != true) return false;
    await ProsaccoMemberAuthApi().recordPrivacyConsent(
      token: token,
      policyVersion: _privacyConsentVersion,
    );
    await sp.setString(_spPrivacyConsentKey, _privacyConsentVersion);
    return true;
  }

  Future<void> _handleLoginSubmitted(String id, String password) async {
    final api = ProsaccoMemberAuthApi();
    final res = await api.login(login: id, password: password);

    if (!mounted) return;

    if (res.needsDeviceBinding) {
      _deviceBindingToken = res.token;
      _deviceBindingChallengeId = res.deviceBindingChallengeId;
    } else if (res.needsMfa) {
      _mfaToken = res.token;
    } else {
      _authToken = res.token;
      PushNotificationsService.setAuthToken(_authToken);
    }
    if (res.displayName != null && res.displayName!.isNotEmpty) {
      _homeDisplayName = res.displayName!;
    } else {
      _setHomeDisplayNameFromIdentifier(id);
    }

    if (res.needsMfa) {
      setState(() {
        _loginIdentifier = id;
        _phase = _AppPhase.otp;
      });
      return;
    }

    if (res.needsDeviceBinding) {
      setState(() {
        _loginIdentifier = id;
        _phase = _AppPhase.otp;
      });
      return;
    }

    if (!await _requireBiometricIfAvailable()) {
      _authToken = null;
      PushNotificationsService.setAuthToken(null);
      throw 'Biometric verification was cancelled.';
    }
    if (_authToken != null && !await _ensurePrivacyConsent(_authToken!)) {
      _authToken = null;
      PushNotificationsService.setAuthToken(null);
      throw 'Privacy consent is required to continue.';
    }

    setState(() {
      _loginIdentifier = null;
      _phase = _AppPhase.home;
    });

    if (_authToken != null) {
      await _persistSession(
        token: _authToken!,
        displayName: _homeDisplayName.trim(),
      );
    }

    final name = _homeDisplayName.trim();
    _enqueueWelcomeSnackBar(name.isNotEmpty ? 'Welcome, $name!' : 'Login successful.');
  }

  Future<void> _handleResendOtp() async {
    if (_deviceBindingToken != null) {
      throw 'Return to sign in to request a new device verification code.';
    }
    final token = _mfaToken;
    if (token == null || token.isEmpty) {
      throw 'Session expired. Please sign in again.';
    }
    final api = ProsaccoMemberAuthApi();
    await api.resendOtp(token: token);
  }

  Future<void> _handleVerifyMfa(String code) async {
    final deviceToken = _deviceBindingToken;
    final deviceChallengeId = _deviceBindingChallengeId;
    if (deviceToken != null && deviceToken.isNotEmpty && deviceChallengeId != null && deviceChallengeId.isNotEmpty) {
      final api = ProsaccoMemberAuthApi();
      final res = await api.verifyDeviceBinding(
        token: deviceToken,
        challengeId: deviceChallengeId,
        code: code,
      );

      if (!mounted) return;
      if (!await _requireBiometricIfAvailable()) {
        throw 'Biometric verification was cancelled.';
      }

      _authToken = res.token;
      PushNotificationsService.setAuthToken(_authToken);
      _deviceBindingToken = null;
      _deviceBindingChallengeId = null;
      if (res.displayName != null && res.displayName!.isNotEmpty) {
        _homeDisplayName = res.displayName!;
      } else {
        _setHomeDisplayNameFromIdentifier(_loginIdentifier);
      }

      setState(() {
        _loginIdentifier = null;
        _phase = _AppPhase.home;
      });

      if (!await _ensurePrivacyConsent(_authToken!)) {
        _authToken = null;
        PushNotificationsService.setAuthToken(null);
        setState(() => _phase = _AppPhase.signIn);
        throw 'Privacy consent is required to continue.';
      }

      await _persistSession(
        token: _authToken!,
        displayName: _homeDisplayName.trim(),
      );
      _enqueueWelcomeSnackBar('Device verified. Biometric login is ready.');
      return;
    }

    final token = _mfaToken;
    if (token == null || token.isEmpty) {
      throw 'Session expired. Please sign in again.';
    }
    final api = ProsaccoMemberAuthApi();
    final res = await api.verifyMfa(token: token, code: code);

    if (!mounted) return;
    if (!await _requireBiometricIfAvailable()) {
      throw 'Biometric verification was cancelled.';
    }

    _authToken = res.token;
    PushNotificationsService.setAuthToken(_authToken);
    _mfaToken = null;
    if (res.displayName != null && res.displayName!.isNotEmpty) {
      _homeDisplayName = res.displayName!;
    } else {
      _setHomeDisplayNameFromIdentifier(_loginIdentifier);
    }

    setState(() {
      _loginIdentifier = null;
      _phase = _AppPhase.home;
    });

    if (!await _ensurePrivacyConsent(_authToken!)) {
      _authToken = null;
      PushNotificationsService.setAuthToken(null);
      setState(() => _phase = _AppPhase.signIn);
      throw 'Privacy consent is required to continue.';
    }

    await _persistSession(
      token: _authToken!,
      displayName: _homeDisplayName.trim(),
    );

    final name = _homeDisplayName.trim();
    _enqueueWelcomeSnackBar(name.isNotEmpty ? 'Welcome back, $name!' : 'Login successful.');
  }
}
