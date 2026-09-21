enum MultigunaLoanStatus { active, overdue }

class MultigunaLoan {
  const MultigunaLoan({
    required this.contractNumber,
    required this.remainingBalance,
    required this.paidProgress,
    required this.installmentAmount,
    required this.scheduleText,
    required this.status,
  });

  final String contractNumber;
  final int remainingBalance;
  final double paidProgress;
  final int installmentAmount;
  final String scheduleText;
  final MultigunaLoanStatus status;
}

class MultigunaOverviewData {
  const MultigunaOverviewData({
    required this.totalObligation,
    required this.availableLimit,
    required this.nextInstallment,
    required this.nextInstallmentContract,
    required this.nextInstallmentDueDate,
    required this.overduePeriods,
    required this.pendingApplicationAmount,
    required this.pendingApplicationTenor,
    required this.pendingApplicationDate,
    required this.loans,
  });

  final int totalObligation;
  final int availableLimit;
  final int nextInstallment;
  final String nextInstallmentContract;
  final String nextInstallmentDueDate;
  final int overduePeriods;
  final int pendingApplicationAmount;
  final int pendingApplicationTenor;
  final String pendingApplicationDate;
  final List<MultigunaLoan> loans;

  static const demo = MultigunaOverviewData(
    totalObligation: 18750000,
    availableLimit: 7250000,
    nextInstallment: 625000,
    nextInstallmentContract: 'MG-2026-001',
    nextInstallmentDueDate: '10 Sep 2026',
    overduePeriods: 1,
    pendingApplicationAmount: 4000000,
    pendingApplicationTenor: 12,
    pendingApplicationDate: '15 Sep 2026',
    loans: [
      MultigunaLoan(
        contractNumber: 'MG-2026-002',
        remainingBalance: 6250000,
        paidProgress: .45,
        installmentAmount: 525000,
        scheduleText: 'Berikutnya 25 Sep 2026',
        status: MultigunaLoanStatus.active,
      ),
      MultigunaLoan(
        contractNumber: 'MG-2025-004',
        remainingBalance: 12500000,
        paidProgress: .30,
        installmentAmount: 625000,
        scheduleText: 'Terlambat 1 periode',
        status: MultigunaLoanStatus.overdue,
      ),
    ],
  );
}
