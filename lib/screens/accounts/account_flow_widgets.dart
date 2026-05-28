import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';

/// Section card used across deposit / withdraw / transfer flows.
class FlowSectionCard extends StatelessWidget {
  const FlowSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: p.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: p.secondary,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

Future<void> showFlowSuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.check_circle_rounded,
}) {
  final p = context.pal;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: p.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: p.outline.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      p.secondaryContainer,
                      p.primary,
                    ],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: p.headlineGreen,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: p.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: ThemeData.estimateBrightnessForColor(
                              p.primary,
                            ) ==
                            Brightness.dark
                        ? Colors.white
                        : const Color(0xFF022C22),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> showFlowConfirmationSheet(
  BuildContext context, {
  required String title,
  required List<(String, String)> rows,
  String confirmLabel = 'Confirm',
  IconData icon = Icons.verified_rounded,
}) async {
  final p = context.pal;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(ctx).bottom + 16,
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: p.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.outline.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: p.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: p.headlineGreen,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...rows.map((row) => _FlowConfirmRow(label: row.$1, value: row.$2)),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: ThemeData.estimateBrightnessForColor(p.primary) ==
                          Brightness.dark
                      ? Colors.white
                      : const Color(0xFF022C22),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: TextStyle(color: p.primary)),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed == true;
}

Future<MemberFeePreview> previewFlowFee(
  BuildContext context, {
  required String authToken,
  required String serviceType,
  required int amountCents,
  Map<String, dynamic>? contextData,
}) async {
  try {
    return await ProsaccoMemberAuthApi().fetchFeePreview(
      token: authToken,
      serviceType: serviceType,
      amountCents: amountCents,
      context: contextData,
    );
  } catch (_) {
    return MemberFeePreview(feeAmount: 0, totalAmount: amountCents);
  }
}

class _FlowConfirmRow extends StatelessWidget {
  const _FlowConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: p.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: p.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showFlowErrorSnack(BuildContext context, String message) {
  final p = context.pal;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.errorContainer,
      content: Text(
        message,
        style: TextStyle(
          color: p.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

Future<void> showTransactionReceiptSheet(
  BuildContext context, {
  required String authToken,
  required String transactionRef,
  required String fallbackTitle,
  required String fallbackMessage,
  IconData icon = Icons.receipt_long_rounded,
}) async {
  if (transactionRef.trim().isEmpty) {
    await showFlowSuccessSheet(
      context,
      title: fallbackTitle,
      message: fallbackMessage,
      icon: icon,
    );
    return;
  }

  MemberReceiptData? receipt;
  try {
    receipt = await ProsaccoMemberAuthApi().fetchMemberReceiptByReference(
      token: authToken,
      reference: transactionRef,
    );
  } catch (_) {
    await showFlowSuccessSheet(
      context,
      title: fallbackTitle,
      message: '$fallbackMessage\n\nReceipt reference: $transactionRef',
      icon: icon,
    );
    return;
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReceiptSheet(receipt: receipt!, icon: icon),
  );
}

class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({required this.receipt, required this.icon});

  final MemberReceiptData receipt;
  final IconData icon;

  String _money(int cents) => (cents / 100).toStringAsFixed(2);

  Future<void> _downloadPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                receipt.saccoName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Receipt ${receipt.reference}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(),
              _pdfRow('Type', receipt.receiptType.replaceAll('_', ' ')),
              _pdfRow('Account', receipt.accountType.replaceAll('_', ' ')),
              _pdfRow('Amount', 'KES ${_money(receipt.amountCents)}'),
              _pdfRow('Payment', receipt.paymentMethod?.replaceAll('_', ' ') ?? '-'),
              _pdfRow('Date', receipt.createdAt),
              pw.Spacer(),
              pw.Text(
                'Thank you. This is a computer-generated receipt.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'ProSacco_Receipt_${receipt.reference}.pdf',
    );
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: p.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: p.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: p.primary, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              'Transaction receipt',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: p.headlineGreen,
                  ),
            ),
            const SizedBox(height: 16),
            _ReceiptRow(label: 'Reference', value: receipt.reference),
            _ReceiptRow(label: 'Type', value: receipt.receiptType.replaceAll('_', ' ')),
            _ReceiptRow(label: 'Account', value: receipt.accountType.replaceAll('_', ' ')),
            _ReceiptRow(label: 'Amount', value: 'KES ${_money(receipt.amountCents)}'),
            _ReceiptRow(label: 'Payment', value: receipt.paymentMethod?.replaceAll('_', ' ') ?? '-'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download receipt'),
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).maybePop();
              },
              child: Text('Close', style: TextStyle(color: p.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: p.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: p.onSurface, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
