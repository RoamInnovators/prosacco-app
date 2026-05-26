import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import 'loan_data.dart';

/// `prosacco design/loan_eligibility/code.html`
class LoanEligibilityScreen extends StatelessWidget {
  const LoanEligibilityScreen({
    super.key,
    required this.product,
  });

  final SaccoLoanProduct product;

  @override
  Widget build(BuildContext context) {
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
        title: const Text('ProSacco'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP 1: CHECK ELIGIBILITY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.pal.primary,
                    ),
              ),
              Text(
                'PROGRESS 25%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.pal.outline,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.25,
              minHeight: 4,
              backgroundColor: context.pal.surfaceContainerHighest,
              color: context.pal.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Loan Assessment Results',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.pal.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our automated system has evaluated your financial profile and transaction history for ${product.name}.',
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.pal.secondaryContainer
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.pal.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: context.pal.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'YOU ARE ELIGIBLE!',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: context.pal.tertiary,
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
                          '1,250,000',
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.pal.surfaceContainerLow
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: context.pal.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reasons for approval',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: context.pal.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _reasonRow(
                            context,
                            'Consistent monthly savings contributions over the last 12 months.',
                          ),
                          _reasonRow(
                            context,
                            'Healthy debt-to-income ratio within SACCO guidelines.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.pal.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want to increase your limit?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                _tipRow(
                  context,
                  Icons.savings_outlined,
                  'Boost monthly savings',
                  'Increasing deposits by ~15% can raise your limit within a few months.',
                ),
                const SizedBox(height: 16),
                _tipRow(
                  context,
                  Icons.history_rounded,
                  'Early repayment history',
                  'Clearing smaller loans early improves your internal credit rating.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Continue to personal loan application when wired.'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.pal.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Select Loan Product',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.pal.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_rounded,
            size: 18,
            color: context.pal.tertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.pal.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(
    BuildContext context,
    IconData icon,
    String title,
    String body,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.pal.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.pal.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.pal.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
