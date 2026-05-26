import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';

class ProfileBeneficiariesScreen extends StatefulWidget {
  const ProfileBeneficiariesScreen({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  State<ProfileBeneficiariesScreen> createState() => _ProfileBeneficiariesScreenState();
}

class _ProfileBeneficiariesScreenState extends State<ProfileBeneficiariesScreen> {
  bool _loading = true;
  String? _error;
  List<MemberBeneficiaryData> _beneficiaries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final api = ProsaccoMemberAuthApi();
      final rows = await api.fetchMemberBeneficiaries(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _beneficiaries = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e?.toString() ?? 'Failed to load beneficiaries.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_loading) {
      return Scaffold(
        backgroundColor: p.surface,
        appBar: AppBar(title: const Text('Beneficiaries')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Beneficiaries')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Nominated beneficiaries for payouts and claims appear here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ..._beneficiaries.map(
            (row) => (row.name, '${row.relationship} · ${row.share}'),
          ).map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                tileColor: p.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: p.outline.withValues(alpha: 0.1)),
                ),
                leading: CircleAvatar(
                  backgroundColor: p.secondaryContainer.withValues(alpha: 0.4),
                  child: Text(
                    e.$1.split(' ').map((w) => w[0]).take(2).join(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: p.primary,
                    ),
                  ),
                ),
                title: Text(e.$1, style: TextStyle(fontWeight: FontWeight.w700, color: p.onSurface)),
                subtitle: Text(e.$2, style: TextStyle(color: p.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded, color: p.outline),
                onTap: () {},
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: null,
            icon: Icon(Icons.add_rounded, color: p.primary),
            label: Text('Add beneficiary (soon)', style: TextStyle(color: p.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
