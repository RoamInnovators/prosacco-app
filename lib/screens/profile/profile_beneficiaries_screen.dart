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
  List<MemberTransferBeneficiaryData> _beneficiaries = const [];

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
          .fetchTransferBeneficiaries(token: widget.authToken);
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

  Future<void> _openBeneficiaryForm([MemberTransferBeneficiaryData? row]) async {
    String type = row?.type ?? 'INTERNAL_MEMBER';
    bool favorite = row?.isFavorite ?? false;
    final nickname = TextEditingController(text: row?.nickname ?? '');
    final memberNumber = TextEditingController(text: row?.recipientMemberNumber ?? '');
    final recipientName = TextEditingController(text: row?.recipientName ?? row?.bankAccountName ?? '');
    final phone = TextEditingController(text: row?.phone ?? '');
    final bankName = TextEditingController(text: row?.bankName ?? '');
    final bankAccount = TextEditingController(text: row?.bankAccountNumber ?? '');
    final mobileNetwork = TextEditingController(text: row?.mobileNetwork ?? '');
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            final payload = <String, dynamic>{
              'type': type,
              'nickname': nickname.text.trim(),
              'isFavorite': favorite,
              if (type == 'INTERNAL_MEMBER')
                'recipientMemberNumber': memberNumber.text.trim(),
              if (type == 'EXTERNAL_BANK') ...{
                'bankName': bankName.text.trim(),
                'bankAccountNumber': bankAccount.text.trim(),
                'bankAccountName': recipientName.text.trim(),
              },
              if (type == 'MOBILE_WALLET') ...{
                'recipientName': recipientName.text.trim(),
                'phone': phone.text.trim(),
                'mobileNetwork': mobileNetwork.text.trim().isEmpty
                    ? null
                    : mobileNetwork.text.trim(),
              },
            };
            setDialogState(() => saving = true);
            try {
              await ProsaccoMemberAuthApi().saveTransferBeneficiary(
                token: widget.authToken,
                id: row?.id,
                payload: payload,
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

          return AlertDialog(
            title: Text(row == null ? 'Add transfer beneficiary' : 'Edit beneficiary'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Beneficiary type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'INTERNAL_MEMBER',
                        child: Text('Internal SACCO member'),
                      ),
                      DropdownMenuItem(
                        value: 'EXTERNAL_BANK',
                        child: Text('External bank account'),
                      ),
                      DropdownMenuItem(
                        value: 'MOBILE_WALLET',
                        child: Text('Mobile wallet'),
                      ),
                    ],
                    onChanged: row == null
                        ? (value) => setDialogState(() {
                              type = value ?? 'INTERNAL_MEMBER';
                            })
                        : null,
                  ),
                  _dialogField('Nickname', nickname),
                  if (type == 'INTERNAL_MEMBER')
                    _dialogField('Recipient member number', memberNumber),
                  if (type == 'EXTERNAL_BANK') ...[
                    _dialogField('Bank name', bankName),
                    _dialogField('Account number', bankAccount,
                        keyboardType: TextInputType.number),
                    _dialogField('Account name', recipientName),
                  ],
                  if (type == 'MOBILE_WALLET') ...[
                    _dialogField('Recipient name', recipientName),
                    _dialogField('Phone number', phone,
                        keyboardType: TextInputType.phone),
                    _dialogField('Mobile network', mobileNetwork),
                  ],
                  SwitchListTile(
                    value: favorite,
                    onChanged: (value) => setDialogState(() => favorite = value),
                    title: const Text('Mark as favorite'),
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
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    nickname.dispose();
    memberNumber.dispose();
    recipientName.dispose();
    phone.dispose();
    bankName.dispose();
    bankAccount.dispose();
    mobileNetwork.dispose();
  }

  Future<void> _deleteBeneficiary(MemberTransferBeneficiaryData row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete beneficiary?'),
        content: Text('Remove ${row.nickname} from your saved transfer beneficiaries?'),
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
      await ProsaccoMemberAuthApi().deleteTransferBeneficiary(
        token: widget.authToken,
        id: row.id,
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
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'EXTERNAL_BANK':
        return 'Bank';
      case 'MOBILE_WALLET':
        return 'Mobile wallet';
      default:
        return 'SACCO member';
    }
  }

  String _subtitle(MemberTransferBeneficiaryData row) {
    if (row.type == 'INTERNAL_MEMBER') {
      return '${row.recipientName ?? 'Member'} · ${row.recipientMemberNumber ?? '—'}';
    }
    if (row.type == 'EXTERNAL_BANK') {
      return '${row.bankName ?? 'Bank'} · ${row.bankAccountNumber ?? '—'}';
    }
    return '${row.recipientName ?? 'Wallet'} · ${row.phone ?? '—'}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(title: const Text('Transfer Beneficiaries')),
      body: _loading
          ? const Center(child: ProsaccoAnimatedLoader(size: 110))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Save frequent recipients for internal SACCO transfers, bank transfers, and mobile wallet transfers.',
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
                        'No transfer beneficiaries saved yet.',
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
                            row.type == 'EXTERNAL_BANK'
                                ? Icons.account_balance_rounded
                                : row.type == 'MOBILE_WALLET'
                                    ? Icons.phone_android_rounded
                                    : Icons.person_rounded,
                            color: p.primary,
                          ),
                        ),
                        title: Text(
                          row.nickname,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: p.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${_typeLabel(row.type)} · ${_subtitle(row)}',
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
