import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';
import 'statement_models.dart';

/// Collect email and request a backend-generated PDF statement.
class RequestStatementScreen extends StatefulWidget {
  const RequestStatementScreen({
    super.key,
    required this.account,
    required this.authToken,
  });

  final StatementAccount account;
  final String authToken;

  @override
  State<RequestStatementScreen> createState() => _RequestStatementScreenState();
}

class _RequestStatementScreenState extends State<RequestStatementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day);
    _fromDate = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fromDate.isAfter(_toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid date range.')),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final accountType = _backendAccountType(widget.account);
    setState(() => _busy = true);

    try {
      final api = ProsaccoMemberAuthApi();
      await api.requestStatementEmail(
        token: widget.authToken,
        accountType: accountType,
        from: _formatYmd(_fromDate),
        to: _formatYmd(_toDate),
        email: email,
      );

      if (!mounted) return;

      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Success',
        barrierColor: Colors.black.withValues(alpha: 0.55),
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
        transitionBuilder: (ctx, anim, _, __) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: _RequestSuccessOverlay(
              animation: anim,
              email: email,
              onDone: () => Navigator.of(ctx).pop(),
            ),
          );
        },
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e?.toString() ?? 'Request failed.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatYmd(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _backendAccountType(StatementAccount account) {
    final explicit = account.backendAccountType;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim().toUpperCase();
    }
    final id = account.id.trim().toLowerCase();
    return switch (id) {
      'bosa' => 'BOSA',
      'fosa' => 'FOSA',
      'shares' => 'SHARES',
      'fd' => 'FD',
      _ => id.toUpperCase(),
    };
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fromDate = DateTime(picked.year, picked.month, picked.day);
      if (_fromDate.isAfter(_toDate)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _toDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.surface,
      appBar: AppBar(
        backgroundColor: context.pal.surface,
        foregroundColor: context.pal.headlineGreen,
        elevation: 0,
        title: const Text(
          'Request statement',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.pal.primary.withValues(alpha: 0.12),
                  context.pal.secondaryContainer.withValues(alpha: 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.pal.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.pal.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    color: context.pal.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secured PDF',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.pal.headlineGreen,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We will email a password-protected copy of your '
                        '${widget.account.name} statement. The unlock password is sent separately for your safety.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.pal.onSurfaceVariant,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Delivery email',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: context.pal.secondary,
                ),
          ),
          const SizedBox(height: 10),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                hintText: 'you@example.com',
                filled: true,
                fillColor: context.pal.surfaceContainerLowest,
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  color: context.pal.primary.withValues(alpha: 0.85),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: context.pal.outline.withValues(alpha: 0.2),
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
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Enter an email address';
                if (!s.contains('@') || !s.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Statement period',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: context.pal.secondary,
                ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickFromDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.pal.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.pal.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'From',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.pal.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    _formatYmd(_fromDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.pal.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickToDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.pal.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.pal.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'To',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.pal.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    _formatYmd(_toDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.pal.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: context.pal.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Request statement',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RequestSuccessOverlay extends StatefulWidget {
  const _RequestSuccessOverlay({
    required this.animation,
    required this.email,
    required this.onDone,
  });

  final Animation<double> animation;
  final String email;
  final VoidCallback onDone;

  @override
  State<_RequestSuccessOverlay> createState() => _RequestSuccessOverlayState();
}

class _RequestSuccessOverlayState extends State<_RequestSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.pal.primary.withValues(alpha: 0.92),
                  context.pal.tertiary.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(
                CurvedAnimation(
                  parent: widget.animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(26, 32, 26, 24),
                  decoration: BoxDecoration(
                    color: context.pal.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + _pulse.value * 0.04,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                context.pal.secondaryContainer,
                                context.pal.primary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.pal.primary
                                    .withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mark_email_read_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Request sent',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: context.pal.headlineGreen,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'A locked PDF statement is on its way to',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.pal.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.pal.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.pal.primary,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your inbox and SMS for the document password.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.pal.slateMuted,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: widget.onDone,
                          style: FilledButton.styleFrom(
                            backgroundColor: context.pal.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
