import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/cartoon_avatar.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'profile_appearance_screen.dart';
import 'profile_beneficiaries_screen.dart';
import 'profile_change_password_screen.dart';
import 'profile_devices_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_kyc_screen.dart';
import 'profile_menu_widgets.dart';
import 'profile_mfa_screen.dart';
import 'profile_notifications_screen.dart';

// ignore: depend_on_referenced_packages
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Profile & security hub — `prosacco design/profile_security/code.html`.
class ProfileSecurityScreen extends StatefulWidget {
  const ProfileSecurityScreen({
    super.key,
    required this.authToken,
    required this.onSignedOut,
  });

  final String authToken;
  final VoidCallback onSignedOut;

  @override
  State<ProfileSecurityScreen> createState() => _ProfileSecurityScreenState();
}

class _ProfileSecurityScreenState extends State<ProfileSecurityScreen> {
  bool _loggingOut = false;
  bool _loading = true;
  bool _uploadingAvatar = false;
  String? _loadError;
  MemberProfileData? _profile;
  MemberSecurityData? _security;
  int _deviceCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileContext();
  }

  Future<void> _loadProfileContext() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final results = await Future.wait([
        api.fetchMemberProfile(token: widget.authToken),
        api.fetchMemberSecurity(token: widget.authToken),
        api.fetchMemberDevices(token: widget.authToken),
      ]);
      if (!mounted) return;
      final devices = results[2] as List<MemberDeviceData>;
      setState(() {
        _profile = results[0] as MemberProfileData;
        _security = results[1] as MemberSecurityData;
        _deviceCount = devices.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load profile.';
        _loading = false;
      });
    }
  }

  Future<void> _chooseAvatarSourceAndUpload() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Allow gallery access to select a profile photo.'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a selfie'),
              subtitle: const Text('Allow camera access to capture a live photo.'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndUploadAvatar(source);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final filename = picked.name.isNotEmpty ? picked.name : 'avatar.jpg';
      final mime = filename.toLowerCase().endsWith('.png') ? 'image/png'
          : filename.toLowerCase().endsWith('.webp') ? 'image/webp'
          : 'image/jpeg';

      final api = ProsaccoMemberAuthApi();
      final avatarUrl = await api.uploadMemberAvatar(
        token: widget.authToken,
        imageBytes: bytes,
        filename: filename,
        mimeType: mime,
      );

      if (!mounted) return;
      // Refresh profile to get updated avatarUrl
      final updated = await api.fetchMemberProfile(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _performLogout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
        content: const Text(
          'We are sad to see you leave. Thank you for using ProSacco.',
        ),
      ),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(milliseconds: 2400), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        return const _GoodbyeDialog();
      },
    );

    if (!mounted) return;
    setState(() => _loggingOut = false);
    widget.onSignedOut();
  }

  void _confirmLogout() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = ctx.pal;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          decoration: BoxDecoration(
            color: p.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.outline.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sign out?',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: p.headlineGreen,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to sign in again to access your accounts.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: p.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _performLogout();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: p.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: p.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_loading) {
      return const Center(
        child: ProsaccoAnimatedLoader(size: 110),
      );
    }

    final profile = _profile;
    final security = _security;
    final name = profile?.fullName ?? 'Member';
    final memberNumber = profile?.memberNumber ?? '—';
    final mfaEnabled = security?.mfaEnabled == true;
    final mfaLabel = mfaEnabled
        ? (security?.mfaMethod == null ? 'ENABLED' : '${security!.mfaMethod!} ENABLED')
        : 'DISABLED';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        const SizedBox(height: 16),
        Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: p.surfaceContainerLowest,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(p),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: p.primary,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: _uploadingAvatar ? null : _chooseAvatarSourceAndUpload,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _uploadingAvatar
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.edit_rounded,
                                size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: p.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              memberNumber,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: p.outline,
                  ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: p.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: p.secondary.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                'MEMBER PROFILE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: p.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _loadError!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const ProfileSectionLabel(text: 'Personal info'),
        ProfileMenuCard(
          children: [
            ProfileMenuTile(
              icon: Icons.person_rounded,
              label: 'Edit profile',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileEditScreen(
                    authToken: widget.authToken,
                    initialFullName: profile?.fullName ?? '',
                    initialPhone: profile?.phone ?? '',
                    initialEmail: profile?.email ?? '',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const ProfileSectionLabel(text: 'Security'),
        ProfileMenuCard(
          children: [
            ProfileMenuTile(
              icon: Icons.shield_rounded,
              label: 'Change password',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileChangePasswordScreen(
                    authToken: widget.authToken,
                  ),
                ),
              ),
            ),
            ProfileMenuTile(
              icon: Icons.verified_user_rounded,
              label: 'Two-factor authentication (MFA)',
              trailing: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mfaLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: p.tertiary,
                    ),
                  ),
                ),
              ),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileMfaScreen(authToken: widget.authToken),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const ProfileSectionLabel(text: 'Devices'),
        ProfileMenuCard(
          children: [
            ProfileMenuTile(
              icon: Icons.devices_rounded,
              label: 'Active devices & sessions',
              trailing: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${_deviceCount == 0 ? 1 : _deviceCount} active session${(_deviceCount == 1 || _deviceCount == 0) ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: p.outline,
                        fontSize: 11,
                      ),
                ),
              ),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileDevicesScreen(authToken: widget.authToken),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const ProfileSectionLabel(text: 'KYC & legal'),
        ProfileMenuCard(
          children: [
            ProfileMenuTile(
              icon: Icons.group_rounded,
              label: 'Beneficiaries',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileBeneficiariesScreen(
                    authToken: widget.authToken,
                  ),
                ),
              ),
            ),
            ProfileMenuTile(
              icon: Icons.file_present_rounded,
              label: 'KYC documents',
              trailing: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'SUBMITTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: p.success,
                    ),
                  ),
                ),
              ),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileKycScreen(authToken: widget.authToken),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const ProfileSectionLabel(text: 'App settings'),
        ProfileMenuCard(
          children: [
            ProfileMenuTile(
              icon: Icons.notifications_outlined,
              label: 'Notification preferences',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileNotificationsScreen(
                    authToken: widget.authToken,
                  ),
                ),
              ),
            ),
            ProfileMenuTile(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileAppearanceScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Material(
          color: p.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _loggingOut ? null : _confirmLogout,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loggingOut)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: p.error,
                      ),
                    )
                  else ...[
                    Icon(Icons.logout_rounded, color: p.error),
                    const SizedBox(width: 10),
                    Text(
                      'Log out',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: p.error,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'VERSION 2.4.1 (BUILD 882)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: p.outline.withValues(alpha: 0.7),
                fontSize: 10,
              ),
        ),
      ],
    );
  }
  Widget _buildAvatarImage(dynamic p) {
    final avatarUrl = _profile?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      final fullUrl = avatarUrl.startsWith('http')
          ? avatarUrl
          : '${ProsaccoMemberAuthApi.baseUrl}$avatarUrl';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CartoonAvatar(
          gender: _profile?.gender,
          size: 112,
        ),
      );
    }
    return CartoonAvatar(
      gender: _profile?.gender,
      size: 112,
    );
  }

  Widget _avatarPlaceholder(dynamic p) {
    return CartoonAvatar(
      gender: _profile?.gender,
      size: 112,
    );
  }
}

class _GoodbyeDialog extends StatelessWidget {
  const _GoodbyeDialog();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: p.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.outline.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.secondaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sentiment_dissatisfied_rounded,
                  size: 40, color: p.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'We are sad to see you leave',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: p.headlineGreen,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Thank you for banking with ProSacco. Sign in anytime to pick up where you left off.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
