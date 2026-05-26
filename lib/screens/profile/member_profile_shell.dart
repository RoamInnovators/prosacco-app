import 'package:flutter/material.dart';

import 'profile_security_screen.dart';

/// Thin wrapper — renders ProfileSecurityScreen directly without a nested
/// Navigator, which previously caused a double back-button press to dismiss.
class MemberProfileShell extends StatelessWidget {
  const MemberProfileShell({
    super.key,
    required this.authToken,
    required this.onSignedOut,
  });

  final String authToken;
  final VoidCallback onSignedOut;

  @override
  Widget build(BuildContext context) {
    return ProfileSecurityScreen(
      authToken: authToken,
      onSignedOut: onSignedOut,
    );
  }
}
