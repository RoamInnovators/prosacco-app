import 'package:flutter/material.dart';

/// Personal / member loan product used in the apply flow.
/// Populated from the real API response via [LoanProductData].
class PersonalLoanProduct {
  const PersonalLoanProduct({
    required this.id,
    required this.name,
    required this.tagline,
    required this.maxAmount,
    required this.minAmount,
    required this.needsGuarantors,
    required this.rateLabel,
    this.minGuarantors = 1,
    this.maxGuarantors = 1,
    this.minRepaymentMonths = 1,
    this.maxRepaymentMonths = 60,
  });

  final String id;
  final String name;
  final String tagline;
  final double maxAmount;
  final double minAmount;
  final bool needsGuarantors;
  final String rateLabel;
  final int minGuarantors;
  final int maxGuarantors;
  final int minRepaymentMonths;
  final int maxRepaymentMonths;
}

/// Maps backend status strings to display labels and colours.
Color loanStatusColor(String status) {
  return switch (status.toUpperCase()) {
    'SUBMITTED' => const Color(0xFF64748B),
    'AWAITING_GUARANTORS' => const Color(0xFFD97706),
    'APPRAISAL_PENDING' => const Color(0xFF2563EB),
    'APPROVED' => const Color(0xFF047857),
    'REJECTED' => const Color(0xFFBA1A1A),
    'DISBURSED' => const Color(0xFF005127),
    _ => const Color(0xFF404940),
  };
}

String loanStatusLabel(String status) {
  return switch (status.toUpperCase()) {
    'SUBMITTED' => 'Submitted',
    'AWAITING_GUARANTORS' => 'Awaiting guarantors',
    'APPRAISAL_PENDING' => 'In review',
    'APPROVED' => 'Approved',
    'REJECTED' => 'Rejected',
    'DISBURSED' => 'Disbursed',
    _ => status,
  };
}
