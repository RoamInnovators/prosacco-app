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
  State<ProfileBeneficiariesScreen> createState() =>
      _ProfileBeneficiariesScreenState();
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
      final rows = await ProsaccoMemberAuthApi()
          .fetchMemberBeneficiaries(token: widget.authToken);
      if (!mounted) return;
      setState(() {
        _beneficiaries = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<String?> _requestOtpAndPrompt() async {
    await ProsaccoMemberAuthApi().requestProfileOtp(
      token: widget.authToken,
      purpose: 'NEXT_OF_KIN_CHANGE',
    );
    if (!mounted) return null;
    final otp = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verify change'),
        content: TextField(
          controller: otp,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'OTP code',
            helperText: 'Enter the verification code sent to you.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, otp.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    otp.dispose();
    return code;
  }

  Future<void> _openBeneficiaryForm([MemberBeneficiaryData? row]) async {
    bool isSecondary = row?.isSecondary ?? false;
    final fullName = TextEditingController(text: row?.fullName ?? '');
    final relationship = TextEditingController(text: row?.relationship == '—' ? '' : row?.relationship ?? '');
    final nationalId = TextEditingController(text: row?.nationalId == '—' ? '' : row?.nationalId ?? '');
    final phone = TextEditingController(text: row?.phone ?? '');
    final email = TextEditingController(text: row?.email ?? '');
    final address = TextEditingController(text: row?.physicalAddress ?? '');
    final dateOfBirth = TextEditingController(text: row?.dateOfBirth ?? '');
    final share = TextEditingController(text: row?.nominationPercent?.toString() ?? '');
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            if (fullName.text.trim().isEmpty || relationship.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter the full name and relationship.')),
              );
              return;
            }
            final otpCode = await _requestOtpAndPrompt();
            if (otpCode == null || otpCode.isEmpty) return;
            final payload = <String, dynamic>{
              'fullName': fullName.text.trim(),
              'relationship': relationship.text.trim(),
              'nationalId': nationalId.text.trim(),
              'phone': phone.text.trim(),
              'email': email.text.trim(),
              'physicalAddress': address.text.trim(),
              'dateOfBirth': dateOfBirth.text.trim(),
              'nominationPercent': int.tryParse(share.text.trim()),
              'isSecondary': isSecondary,
            };
            setDialogState(() => saving = true);
            try {
              await ProsaccoMemberAuthApi().saveMemberBeneficiary(
                token: widget.authToken,
                id: row?.id,
                payload: payload,
                otpCode: otpCode,
              );
              if (!mounted) return;
              Navigator.pop(dialogContext);
              await _load();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(row == null
                      ? 'Beneficiary added.'
                      : 'Beneficiary updated.'),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            } finally {
              if (context.mounted) setDialogState(() => saving = false);
            }
          }

          final p = context.pal;
          return AlertDialog(
            backgroundColor: p.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded, color: p.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row == null ? 'Add share beneficiary' : 'Edit beneficiary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: p.headlineGreen,
                        ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add next of kin or nominees who can receive your shares or benefits according to your SACCO records.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: p.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _dialogField('Full name', fullName),
                  _dialogField('Relationship', relationship),
                  _dialogField('National ID / Passport', nationalId),
                  _dialogField('Phone number', phone, keyboardType: TextInputType.phone),
                  _dialogField('Email', email, keyboardType: TextInputType.emailAddress),
                  _dialogField('Physical address', address),
                  _dialogField('Date of birth (YYYY-MM-DD)', dateOfBirth),
                  _dialogField('Nomination share %', share, keyboardType: TextInputType.number),
                  SwitchListTile(
                    value: isSecondary,
                    onChanged: (value) => setDialogState(() => isSecondary = value),
                    title: const Text('Secondary beneficiary'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving ? null : save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    fullName.dispose();
    relationship.dispose();
    nationalId.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    dateOfBirth.dispose();
    share.dispose();
  }

  Future<void> _deleteBeneficiary(MemberBeneficiaryData row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete beneficiary?'),
        content: Text('Remove ${row.fullName} from your next-of-kin beneficiaries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: context.pal.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final otpCode = await _requestOtpAndPrompt();
      if (otpCode == null || otpCode.isEmpty) return;
      await ProsaccoMemberAuthApi().deleteMemberBeneficiary(
        token: widget.authToken,
        id: row.id,
        otpCode: otpCode,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiary deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _dialogField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: context.pal.surfaceContainerLow,
        ),
      ),
    );
  }

  String _subtitle(MemberBeneficiaryData row) {
    final share = row.nominationPercent == null ? row.share : '${row.nominationPercent}%';
    return '${row.relationship} · Share: $share · ${row.phone.isEmpty ? 'No phone' : row.phone}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Share Beneficiaries')),
      body: _loading
          ? const Center(child: ProsaccoAnimatedLoader(size: 110))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Manage next of kin and nominees linked to your shares and member benefits. Transfer beneficiaries are managed from transfer flows.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: p.error)),
                    ),
                  if (_beneficiaries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: p.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.outline.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        'No share beneficiaries or next of kin saved yet.',
                        style: TextStyle(color: p.onSurfaceVariant),
                      ),
                    ),
                  ..._beneficiaries.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        tileColor: p.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: p.outline.withValues(alpha: 0.1)),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: p.secondaryContainer.withValues(alpha: 0.4),
                          child: Icon(
                            row.isSecondary
                                ? Icons.group_rounded
                                : Icons.volunteer_activism_rounded,
                            color: p.primary,
                          ),
                        ),
                        title: Text(
                          row.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: p.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          _subtitle(row),
                          style: TextStyle(color: p.onSurfaceVariant),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _openBeneficiaryForm(row);
                            if (value == 'delete') _deleteBeneficiary(row);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        onTap: () => _openBeneficiaryForm(row),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openBeneficiaryForm(),
                    icon: Icon(Icons.add_rounded, color: p.primary),
                    label: Text(
                      'Add beneficiary',
                      style: TextStyle(
                        color: p.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
