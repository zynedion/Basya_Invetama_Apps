enum MultigunaLoanStatus { active, overdue }

class MultigunaLoan {
  const MultigunaLoan({
    required this.contractNumber,
    required this.startDate,
    required this.endDate,
    required this.installmentAmount,
    required this.totalPayment,
    required this.remainingBalance,
    required this.dueDay,
    required this.nextDueDate,
    required this.paidInstallments,
    required this.totalInstallments,
    required this.nextInstallmentNumber,
    required this.collectibilityValue,
    required this.collectibilityLabel,
    required this.collectibilityCategory,
    required this.paymentStatusCode,
    required this.paymentStatusLabel,
    required this.arrearsMonths,
    required this.arrearsAmount,
  });

  final String contractNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int installmentAmount;
  final int totalPayment;
  final int remainingBalance;
  final int dueDay;
  final DateTime nextDueDate;
  final int paidInstallments;
  final int totalInstallments;
  final int nextInstallmentNumber;
  final int collectibilityValue;
  final String collectibilityLabel;
  final String collectibilityCategory;
  final String paymentStatusCode;
  final String paymentStatusLabel;
  final int arrearsMonths;
  final int arrearsAmount;

  bool get isOverdue => paymentStatusCode.toLowerCase() == 'overdue';
  MultigunaLoanStatus get status =>
      isOverdue ? MultigunaLoanStatus.overdue : MultigunaLoanStatus.active;
  double get paidProgress => totalInstallments <= 0
      ? 0
      : (paidInstallments / totalInstallments).clamp(0, 1).toDouble();
  int get nextAmount => arrearsAmount > 0 ? arrearsAmount : installmentAmount;
}

class MultigunaOverviewData {
  const MultigunaOverviewData({
    required this.accessible,
    required this.currency,
    required this.hasMultiguna,
    required this.totalContracts,
    required this.totalInstallment,
    required this.totalObligation,
    required this.loans,
  });

  final bool accessible;
  final String currency;
  final bool hasMultiguna;
  final int totalContracts;
  final int totalInstallment;
  final int totalObligation;
  final List<MultigunaLoan> loans;

  bool get hasActiveLoan =>
      accessible && hasMultiguna && totalContracts > 0 && loans.isNotEmpty;

  MultigunaLoan? get nearestLoan {
    if (loans.isEmpty) return null;
    final sorted = [...loans]
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        return a.nextDueDate.compareTo(b.nextDueDate);
      });
    return sorted.first;
  }

  static const unavailable = MultigunaOverviewData(
    accessible: false,
    currency: 'IDR',
    hasMultiguna: false,
    totalContracts: 0,
    totalInstallment: 0,
    totalObligation: 0,
    loans: [],
  );

  static final demo = MultigunaOverviewData(
    accessible: true,
    currency: 'IDR',
    hasMultiguna: true,
    totalContracts: 2,
    totalInstallment: 1150000,
    totalObligation: 18750000,
    loans: [
      MultigunaLoan(
        contractNumber: 'MG-2026-002',
        startDate: DateTime(2026, 1, 25),
        endDate: DateTime(2028, 1, 25),
        installmentAmount: 525000,
        totalPayment: 5750000,
        remainingBalance: 6250000,
        dueDay: 25,
        nextDueDate: DateTime(2026, 9, 25),
        paidInstallments: 11,
        totalInstallments: 24,
        nextInstallmentNumber: 12,
        collectibilityValue: 0,
        collectibilityLabel: 'COL 0',
        collectibilityCategory: 'normal',
        paymentStatusCode: 'due',
        paymentStatusLabel: 'Waktu Bayar',
        arrearsMonths: 0,
        arrearsAmount: 0,
      ),
      MultigunaLoan(
        contractNumber: 'MG-2025-004',
        startDate: DateTime(2025, 10, 10),
        endDate: DateTime(2027, 10, 10),
        installmentAmount: 625000,
        totalPayment: 5250000,
        remainingBalance: 12500000,
        dueDay: 10,
        nextDueDate: DateTime(2026, 9, 10),
        paidInstallments: 8,
        totalInstallments: 24,
        nextInstallmentNumber: 9,
        collectibilityValue: -1,
        collectibilityLabel: 'COL -1',
        collectibilityCategory: 'warning',
        paymentStatusCode: 'overdue',
        paymentStatusLabel: 'Cicilan Belum Dibayar',
        arrearsMonths: 1,
        arrearsAmount: 625000,
      ),
    ],
  );
}
