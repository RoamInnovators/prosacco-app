import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import '../../widgets/prosacco_animated_loader.dart';
import 'statement_models.dart';

class StatementViewerScreen extends StatefulWidget {
  const StatementViewerScreen({
    super.key,
    required this.account,
    required this.authToken,
  });

  final StatementAccount account;
  final String authToken;

  @override
  State<StatementViewerScreen> createState() => _StatementViewerScreenState();
}

class _StatementViewerScreenState extends State<StatementViewerScreen> {
  StatementGenerateResult? _result;
  bool _loading = true;
  String? _loadError;
  bool _generatingPdf = false;

  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month, now.day);
    _load();
  }

  String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _fmtDisplay(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]} ${d.year}';
  }

  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final api = ProsaccoMemberAuthApi();
      final result = await api.generateStatement(
        token: widget.authToken,
        accountType: widget.account.backendAccountType ?? widget.account.id.toUpperCase(),
        from: _fmt(_from),
        to: _fmt(_to),
      );
      if (!mounted) return;
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadError = e?.toString() ?? 'Failed to load statement.'; _loading = false; });
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked == null || !mounted) return;
    setState(() => _from = picked);
    _load();
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(context: context, initialDate: _to, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked == null || !mounted) return;
    setState(() => _to = picked);
    _load();
  }

  Future<Uint8List> _buildPdf() async {
    final result = _result!;
    final doc = pw.Document();
    final green = PdfColor.fromHex('#005127');
    final greenLight = PdfColor.fromHex('#e8f5ee');
    final greenMid = PdfColor.fromHex('#c2e0ce');
    final greenContainer = PdfColor.fromHex('#1b6b3a');
    final ink = PdfColor.fromHex('#0e1a14');
    final muted = PdfColor.fromHex('#4a6358');
    final debit = PdfColor.fromHex('#7a1c1c');
    final credit = PdfColor.fromHex('#005127');
    final white = PdfColors.white;

    final closing = result.closingBalance;
    final opening = result.openingBalance;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => [
          // ── Header band ──
          pw.Container(
            color: green,
            padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ProSacco', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: white)),
                        pw.SizedBox(height: 2),
                        pw.Text('SAVINGS & CREDIT COOPERATIVE', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#ffffff88'), letterSpacing: 1.5)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Statement', style: pw.TextStyle(fontSize: 28, fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex('#ffffffe6'))),
                        pw.SizedBox(height: 4),
                        pw.Text('${result.accountType} · ${result.accountNumber}', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#ffffff80'), letterSpacing: 1.2)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  children: [
                    _metaCell(ctx, 'Period', '${_fmtDisplay(_from)} – ${_fmtDisplay(_to)}', white),
                    pw.SizedBox(width: 40),
                    _metaCell(ctx, 'Generated on', _fmtDisplay(DateTime.now()), white),
                    pw.SizedBox(width: 40),
                    _metaCell(ctx, 'Account type', widget.account.name, white),
                  ],
                ),
              ],
            ),
          ),
          // ── Status ribbon ──
          pw.Container(
            color: greenContainer,
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: pw.Row(
              children: [
                pw.Container(width: 7, height: 7, decoration: pw.BoxDecoration(color: PdfColor.fromHex('#6dffb0'), shape: pw.BoxShape.circle)),
                pw.SizedBox(width: 8),
                pw.Text('Account in good standing', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#ffffffbf'), letterSpacing: 1.2)),
              ],
            ),
          ),
          // ── Body ──
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Summary cards
                pw.Text('ACCOUNT SUMMARY', style: pw.TextStyle(fontSize: 9, color: muted, letterSpacing: 1.5)),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    if (opening != null) ...[
                      _sumCard(ctx, 'Opening Balance', 'KES ${formatKesMoney(opening)}', green, greenLight, greenMid, ink, muted, false),
                      pw.SizedBox(width: 10),
                    ],
                    _sumCard(ctx, 'Total Credits', '+ KES ${formatKesMoney(result.totalCredits)}', green, greenLight, greenMid, credit, muted, false),
                    pw.SizedBox(width: 10),
                    _sumCard(ctx, 'Total Debits', '- KES ${formatKesMoney(result.totalDebits)}', green, greenLight, greenMid, debit, muted, false),
                    if (closing != null) ...[
                      pw.SizedBox(width: 10),
                      _sumCard(ctx, 'Closing Balance', 'KES ${formatKesMoney(closing)}', green, greenLight, greenMid, white, white, true),
                    ],
                  ],
                ),
                pw.SizedBox(height: 24),
                // Transactions table
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TRANSACTION HISTORY', style: pw.TextStyle(fontSize: 9, color: muted, letterSpacing: 1.5)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(color: greenLight, borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('${result.transactions.length} transactions', style: pw.TextStyle(fontSize: 9, color: greenContainer)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder(bottom: pw.BorderSide(color: greenMid, width: 0.5)),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(3),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1.5),
                    5: const pw.FlexColumnWidth(1.5),
                    6: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: greenMid, width: 0.5))),
                      children: ['Date','Reference','Description','Type','Debit','Credit','Balance']
                          .map((h) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                child: pw.Text(h.toUpperCase(), style: pw.TextStyle(fontSize: 8, color: muted, letterSpacing: 0.8)),
                              ))
                          .toList(),
                    ),
                    ...result.transactions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final t = entry.value;
                      final isCredit = t.isCredit;
                      final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#f0faf4');
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: bg),
                        children: [
                          _cell(t.date, muted, 8),
                          _cell(t.reference ?? '', muted, 8),
                          _cell(t.typeLabel, ink, 9, bold: true),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: isCredit ? greenLight : PdfColor.fromHex('#fdf3f3'),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(isCredit ? 'Credit' : 'Debit', style: pw.TextStyle(fontSize: 8, color: isCredit ? credit : debit)),
                            ),
                          ),
                          _cell(isCredit ? '—' : formatKesMoney(t.amountKes), isCredit ? muted : debit, 9, right: true),
                          _cell(isCredit ? formatKesMoney(t.amountKes) : '—', isCredit ? credit : muted, 9, right: true, bold: isCredit),
                          _cell(t.balanceAfterKes != null ? formatKesMoney(t.balanceAfterKes!) : '—', ink, 9, right: true, bold: true),
                        ],
                      );
                    }),
                    // Closing balance row
                    if (closing != null)
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: green),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: pw.Text('Closing Balance — ${_fmtDisplay(_to)}', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#ffffff99'), letterSpacing: 1)),
                          ),
                          pw.SizedBox(), pw.SizedBox(), pw.SizedBox(), pw.SizedBox(),
                          pw.SizedBox(),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: pw.Text('KES ${formatKesMoney(closing)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: white), textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 32),
                // Footer
                pw.Divider(color: greenMid, thickness: 0.5),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('This statement is system-generated by ProSacco Member Portal and is valid without a signature.', style: pw.TextStyle(fontSize: 9, color: muted)),
                        pw.SizedBox(height: 3),
                        pw.Text('For disputes, contact accounts@prosacco.co.ke within 30 days.', style: pw.TextStyle(fontSize: 9, color: muted)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 100, height: 0.5, color: greenMid),
                        pw.SizedBox(height: 4),
                        pw.Text('AUTHORISED BY SYSTEM', style: pw.TextStyle(fontSize: 9, color: muted, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        footer: (ctx) => pw.Container(
          color: green,
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('prosacco.co.ke · Member Portal', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#ffffff80'))),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#ffffff66'))),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _metaCell(pw.Context ctx, String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#ffffff73'), letterSpacing: 1.5)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  static pw.Widget _sumCard(pw.Context ctx, String label, String value, PdfColor green, PdfColor bg, PdfColor border, PdfColor valueColor, PdfColor labelColor, bool accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: accent ? green : bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: accent ? green : border, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 8, color: labelColor, letterSpacing: 1)),
            pw.SizedBox(height: 5),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, PdfColor color, double size, {bool right = false, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: size, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_result == null) return;
    setState(() => _generatingPdf = true);
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'ProSacco_Statement_${widget.account.name.replaceAll(' ', '_')}_${_fmt(_from)}_${_fmt(_to)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e')));
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _printPdf() async {
    if (_result == null) return;
    setState(() => _generatingPdf = true);
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print error: $e')));
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.headlineGreen,
        elevation: 0,
        title: Text(widget.account.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          if (_result != null && !_loading)
            IconButton(
              icon: _generatingPdf
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded),
              onPressed: _generatingPdf ? null : _downloadPdf,
              tooltip: 'Download PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          // Date range picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(child: _DateChip(label: 'From', value: _fmt(_from), onTap: _pickFrom)),
                const SizedBox(width: 10),
                Expanded(child: _DateChip(label: 'To', value: _fmt(_to), onTap: _pickTo)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: ProsaccoAnimatedLoader(size: 88))
                : _loadError != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_loadError!, style: Theme.of(context).textTheme.bodyMedium))
                    : _StatementBody(
                        account: widget.account,
                        result: _result!,
                        from: _fmtDisplay(_from),
                        to: _fmtDisplay(_to),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _result != null && !_loading
          ? _BottomBar(
              onPdf: _generatingPdf ? null : _downloadPdf,
              onPrint: _generatingPdf ? null : _printPdf,
              generating: _generatingPdf,
            )
          : null,
    );
  }
}

// ── Date chip ─────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: p.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: p.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12)),
            Text(value, style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onPdf, required this.onPrint, required this.generating});
  final VoidCallback? onPdf;
  final VoidCallback? onPrint;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.surfaceContainerLowest,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Print', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onPdf,
                  icon: generating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(generating ? 'Generating…' : 'Download PDF', style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── On-screen statement body ──────────────────────────────────────────────────

class _StatementBody extends StatelessWidget {
  const _StatementBody({
    required this.account,
    required this.result,
    required this.from,
    required this.to,
  });

  final StatementAccount account;
  final StatementGenerateResult result;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final closing = result.closingBalance;
    final opening = result.openingBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header card ──
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Green header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [p.primary, p.primaryContainer],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ProSacco', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                              Text('SAVINGS & CREDIT COOPERATIVE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54, letterSpacing: 1.5, fontSize: 9)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Statement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w300)),
                              Text('${result.accountType} · ${result.accountNumber}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54, letterSpacing: 1)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _MetaCell(label: 'Period', value: '$from – $to'),
                          const SizedBox(width: 24),
                          _MetaCell(label: 'Account', value: account.name),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status ribbon
                Container(
                  color: p.primaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: const Color(0xFF6DFFB0), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Account in good standing', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Summary cards ──
          Row(
            children: [
              if (opening != null) ...[
                Expanded(child: _SumCard(label: 'Opening', value: 'KES ${formatKesMoney(opening)}', accent: false)),
                const SizedBox(width: 8),
              ],
              Expanded(child: _SumCard(label: 'Credits', value: '+ ${formatKesMoney(result.totalCredits)}', accent: false, valueColor: p.success)),
              const SizedBox(width: 8),
              Expanded(child: _SumCard(label: 'Debits', value: '- ${formatKesMoney(result.totalDebits)}', accent: false, valueColor: p.error)),
              if (closing != null) ...[
                const SizedBox(width: 8),
                Expanded(child: _SumCard(label: 'Closing', value: 'KES ${formatKesMoney(closing)}', accent: true)),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ── Transactions ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TRANSACTIONS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.onSurfaceVariant, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text('${result.transactions.length} txns', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (result.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No transactions in this period.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.onSurfaceVariant))),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: p.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.outline.withValues(alpha: 0.12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Table header
                  Container(
                    color: p.primary.withValues(alpha: 0.06),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _th(context, 'Date')),
                        Expanded(flex: 3, child: _th(context, 'Type')),
                        Expanded(flex: 2, child: _th(context, 'Debit', right: true)),
                        Expanded(flex: 2, child: _th(context, 'Credit', right: true)),
                        Expanded(flex: 2, child: _th(context, 'Balance', right: true)),
                      ],
                    ),
                  ),
                  ...result.transactions.asMap().entries.map((e) => _TxnRow(txn: e.value, alt: e.key.isOdd)),
                  // Closing balance row
                  if (closing != null)
                    Container(
                      color: p.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 9,
                            child: Text('Closing Balance — $to', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white60, letterSpacing: 1)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('KES ${formatKesMoney(closing)}', textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Footer ──
          Divider(color: p.outline.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'This statement is system-generated by ProSacco Member Portal and is valid without a signature.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.onSurfaceVariant, height: 1.5),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(width: 80, height: 0.5, color: p.outline.withValues(alpha: 0.4)),
                  const SizedBox(height: 4),
                  Text('AUTHORISED BY SYSTEM', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.onSurfaceVariant, letterSpacing: 1, fontSize: 9)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _th(BuildContext context, String t, {bool right = false}) {
    return Text(t.toUpperCase(),
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6, color: context.pal.onSurfaceVariant, fontSize: 9));
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54, letterSpacing: 1.5, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SumCard extends StatelessWidget {
  const _SumCard({required this.label, required this.value, required this.accent, this.valueColor});
  final String label;
  final String value;
  final bool accent;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent ? p.primary : p.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent ? p.primary : p.primary.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent ? Colors.white60 : p.onSurfaceVariant, fontSize: 9, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: accent ? Colors.white : (valueColor ?? p.onSurface), fontSize: 11)),
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.alt});
  final StatementTxnRow txn;
  final bool alt;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isCredit = txn.isCredit;
    return Container(
      color: alt ? p.surfaceContainerLow.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(txn.date, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.onSurfaceVariant, fontSize: 11))),
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(txn.typeLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
              if (txn.reference != null && txn.reference!.isNotEmpty)
                Text(txn.reference!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.onSurfaceVariant, fontSize: 10)),
            ],
          )),
          Expanded(flex: 2, child: Text(isCredit ? '—' : formatKesMoney(txn.amountKes), textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isCredit ? p.onSurfaceVariant : p.error, fontWeight: isCredit ? FontWeight.w400 : FontWeight.w700, fontSize: 11))),
          Expanded(flex: 2, child: Text(isCredit ? formatKesMoney(txn.amountKes) : '—', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isCredit ? p.success : p.onSurfaceVariant, fontWeight: isCredit ? FontWeight.w800 : FontWeight.w400, fontSize: 11))),
          Expanded(flex: 2, child: Text(txn.balanceAfterKes != null ? formatKesMoney(txn.balanceAfterKes!) : '—', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11))),
        ],
      ),
    );
  }
}
