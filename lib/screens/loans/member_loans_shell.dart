import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import 'guarantor_inbox_tab.dart';
import 'loans_catalog_tab.dart';
import 'personal_loans_tab.dart';

/// Loans area: redesigned to match the newer app while preserving existing API tabs.
class MemberLoansShell extends StatelessWidget {
  const MemberLoansShell({super.key, required this.tabController, required this.authToken});

  final TabController tabController;
  final String authToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: context.pal.surface,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loans',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.pal.headlineGreen,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Apply, track applications, and review guarantor requests.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.pal.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: context.pal.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.pal.outline.withValues(alpha: 0.12)),
                ),
                child: TabBar(
                  controller: tabController,
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  labelColor: context.pal.primary,
                  unselectedLabelColor: context.pal.slateMuted,
                  indicatorColor: context.pal.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                  unselectedLabelStyle:
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                  tabs: const [
                    Tab(text: 'Mobile Loans'),
                    Tab(text: 'Personal Loans'),
                    Tab(text: 'Guarantor Center'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              LoansCatalogTab(authToken: authToken),
              PersonalLoansTab(authToken: authToken),
              GuarantorInboxTab(authToken: authToken),
            ],
          ),
        ),
      ],
    );
  }
}
