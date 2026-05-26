import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';

/// KYC documents — status shown as submitted (per product brief).
class ProfileKycScreen extends StatefulWidget {
  const ProfileKycScreen({
    super.key,
    required this.authToken,
  });

  final String authToken;

  @override
  State<ProfileKycScreen> createState() => _ProfileKycScreenState();
}

class _ProfileKycScreenState extends State<ProfileKycScreen> {
  bool _loading = true;
  String? _error;
  List<MemberKycDocumentData> _docs = const [];

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
      final docs = await api.fetchMemberKycDocuments(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e?.toString() ?? 'Failed to load documents.';
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
        appBar: AppBar(title: const Text('KYC documents')),
        body: const Center(child: ProsaccoAnimatedLoader(size: 110)),
      );
    }
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('KYC documents')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.primary.withValues(alpha: 0.12),
                  p.secondaryContainer.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.assignment_turned_in_rounded,
                      color: p.success, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submitted',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: p.headlineGreen,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your identity documents are on file and verified. '
                        'You do not need to upload again unless we request a refresh.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: p.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
            ),
          Text(
            'ON FILE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: p.secondary,
                ),
          ),
          const SizedBox(height: 12),
          if (_docs.isEmpty)
            Text(
              'No KYC documents found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.onSurfaceVariant,
                  ),
            )
          else
            ..._docs.map(
              (d) => _docRow(
                context,
                d.type,
                '${d.number} · ${d.uploaded}',
                d.status,
              ),
            ),
        ],
      ),
    );
  }

  Widget _docRow(
    BuildContext context,
    String title,
    String meta,
    String status,
  ) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: p.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: p.onSurface,
                    ),
                  ),
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.slateMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: p.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
