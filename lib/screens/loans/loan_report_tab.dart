import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import 'loan_data.dart';

class LoanReportTab extends StatefulWidget {
  const LoanReportTab({super.key, required this.authToken, required this.applications});

  final String authToken;
  final List<LoanApplicationData> applications;

  @override
  State<LoanReportTab> createState() => _LoanReportTabState();
}

class _LoanReportTabState extends State<LoanReportTab> {
  String? _selectedLoanId;
  bool _busy = false;
  String? _message;
  Map<String, dynamic>? _preview;
  String? _downloadUrl;

  List<LoanApplicationData> get _activeLoans => widget.applications
      .where((a) => a.loanAccountStatus == 'ACTIVE' || a.status == 'DISBURSED')
      .toList();

  Future<void> _generate() async {
    final loanId = _selectedLoanId;
    if (loanId == null) return;
    setState(() {
      _busy = true;
      _message = null;
      _preview = null;
      _downloadUrl = null;
    });
    try {
      final api = ProsaccoMemberAuthApi();
      final res = await api.requestLoanReport(token: widget.authToken, loanAccountId: loanId);
      if ('${res['status']}' == 'PENDING_APPROVAL') {
        setState(() => _message = res['message']?.toString() ?? 'Pending approval');
        return;
      }
      final doc = res['document'];
      final docId = doc is Map ? doc['id']?.toString() : null;
      if (docId == null) throw 'No document id returned';
      final preview = await api.loanReportPreview(token: widget.authToken, documentId: docId);
      final dl = await api.loanReportDownload(token: widget.authToken, documentId: docId);
      setState(() {
        _preview = preview['preview'] as Map<String, dynamic>?;
        _downloadUrl = (dl['document'] as Map?)?['downloadUrl']?.toString();
      });
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDownload() async {
    final url = _downloadUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _message = 'Signed PDF download link copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    if (_activeLoans.isEmpty) {
      return Center(
        child: Text('No active loans', style: TextStyle(color: context.pal.onSurfaceVariant)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Loan Report', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedLoanId,
          decoration: const InputDecoration(labelText: 'Select loan'),
          items: _activeLoans
              .map((l) => DropdownMenuItem(
                    value: l.loanAccountId,
                    child: Text(l.productName ?? 'Loan'),
                  ))
              .where((item) => item.value != null && item.value!.isNotEmpty)
              .toList(),
          onChanged: (v) => setState(() => _selectedLoanId = v),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy || _selectedLoanId == null ? null : _generate,
          child: Text(_busy ? 'Generating...' : 'Generate / Preview'),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, style: TextStyle(color: context.pal.error)),
        ],
        if (_preview != null) ...[
          const SizedBox(height: 16),
          Text('${_preview!['memberName'] ?? ''}'),
          Text('Loan ${_preview!['loanNumber'] ?? ''}'),
          Text('Classification: ${_preview!['classification'] ?? ''}'),
          if (_downloadUrl != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _openDownload, child: const Text('Download PDF')),
          ],
        ],
      ],
    );
  }
}
