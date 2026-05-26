import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'statement_account_hub_screen.dart';
import 'statement_models.dart';

/// Choose which account statements apply to, then open the hub.
class StatementAccountPickScreen extends StatefulWidget {
  const StatementAccountPickScreen({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  State<StatementAccountPickScreen> createState() =>
      _StatementAccountPickScreenState();
}

class _StatementAccountPickScreenState extends State<StatementAccountPickScreen> {
  StatementAccount? _selected;
  List<StatementAccount> _accounts = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      final api = ProsaccoMemberAuthApi();
      final accounts = await api.fetchMemberStatementsAccounts(
        token: widget.authToken,
      );
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _selected = accounts.isNotEmpty ? accounts.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e?.toString() ?? 'Failed to load accounts.';
        _accounts = const [];
        _selected = null;
        _loading = false;
      });
    }
  }

  void _goHub() {
    final a = _selected;
    if (a == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => StatementAccountHubScreen(
          account: a,
          authToken: widget.authToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: ProsaccoAnimatedLoader(size: 110),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Text(
          'Statements',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.pal.headlineGreen,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick the account you want to work with. You can view on-screen, '
          'request a secured PDF by email, or browse transfers.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.pal.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: context.pal.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.pal.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ACCOUNT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: context.pal.secondary,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.pal.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.pal.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.pal.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.pal.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StatementAccount>(
                    value: _selected,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.pal.primary,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    items: _accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(
                              a.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: context.pal.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selected = v),
                  ),
                ),
              ),
          if (_loadError != null && _selected == null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                _loadError!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
              if (_selected != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.pal.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.pal.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: context.pal.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_selected!.accountMask} · ${_selected!.tagline}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.pal.onSurfaceVariant,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _goHub,
                style: FilledButton.styleFrom(
                  backgroundColor: context.pal.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
