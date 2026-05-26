import 'package:flutter/material.dart';

import 'statement_account_pick_screen.dart';

/// Renders the statement account picker directly — no nested Navigator.
/// Sub-pages (hub, viewer, etc.) are pushed via the root navigator as
/// full-screen routes, so there is only ever one AppBar visible at a time.
class MemberStatementsShell extends StatelessWidget {
  const MemberStatementsShell({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  Widget build(BuildContext context) {
    return StatementAccountPickScreen(authToken: authToken);
  }
}
