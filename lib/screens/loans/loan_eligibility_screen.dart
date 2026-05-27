import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import '../../utils/prosacco_member_auth_api.dart';

/// Loan eligibility view backed by live product data from the SACCO.
class LoanEligibilityScreen extends StatelessWidget {
  const LoanEligibilityScreen({
    super.key,
    required this.product,
    required this.authToken,
  });

  final LoanProductData product;
  final String authToken;

  String _kes(int cents) {
    final v = cents / 100;
    final parts = v.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final eligible = product.eligible;
    final limitCents = product.memberMaxEligibleCents;

    return Scaffold(
      backgroundColor: context.pal.surface,
      appBar: AppBar(
        backgroundColor: context.pal.surface,
        foregroundColor: context.pal.headlineGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Loan eligibility'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            product.productName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.pal.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description ?? 'Eligibility based on your SACCO profile.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.pal.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.pal.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (eligible ? context.pal.tertiary : context.pal.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        eligible
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 18,
                        color: eligible ? context.pal.tertiary : context.pal.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        eligible ? 'YOU ARE ELIGIBLE' : 'NOT ELIGIBLE',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: eligible
                                  ? context.pal.tertiary
                                  : context.pal.error,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'MAXIMUM QUALIFYING LIMIT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: context.pal.outline,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      eligible ? _kes(limitCents) : '—',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.pal.onSurface,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'KES',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.pal.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                    ),
                  ],
                ),
                if (!eligible && product.ineligibleReason != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    product.ineligibleReason!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.pal.error,
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (eligible)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: context.pal.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Continue to application',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
