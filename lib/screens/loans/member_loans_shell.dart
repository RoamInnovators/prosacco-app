import 'package:flutter/material.dart';

import '../../theme/prosacco_palette.dart';
import 'guarantor_inbox_tab.dart';
import 'loans_catalog_tab.dart';
import 'personal_loans_tab.dart';

/// Loans area: horizontal main tabs — Loans | Personal Loans | Guarantor requests.
class MemberLoansShell extends StatelessWidget {
  const MemberLoansShell({super.key, required this.tabController, required this.authToken});

  final TabController tabController;
  final String authToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: context.pal.surface,
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: context.pal.primary,
            unselectedLabelColor: context.pal.slateMuted,
            indicatorColor: context.pal.primary,
            indicatorWeight: 3,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            unselectedLabelStyle:
                Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
            tabs: const [
              Tab(text: 'Loans'),
              Tab(text: 'Personal Loans'),
              Tab(text: 'Guarantor requests'),
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
