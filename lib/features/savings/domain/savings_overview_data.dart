enum SavingsTransactionDirection { incoming, outgoing, neutral }

class SavingsTransaction {
  const SavingsTransaction({
    required this.title,
    required this.date,
    required this.status,
    required this.amount,
    required this.direction,
  });

  final String title;
  final String date;
  final String status;
  final int amount;
  final SavingsTransactionDirection direction;
}

class SavingsOverviewData {
  const SavingsOverviewData({
    required this.voluntarySavings,
    required this.annualShu,
    required this.mandatorySavings,
    required this.principalSavings,
    required this.shuYear,
    required this.transactions,
  });

  final int voluntarySavings;
  final int annualShu;
  final int mandatorySavings;
  final int principalSavings;
  final int shuYear;
  final List<SavingsTransaction> transactions;

  static const demo = SavingsOverviewData(
    voluntarySavings: 12500000,
    annualShu: 825000,
    mandatorySavings: 2000000,
    principalSavings: 1000000,
    shuYear: 2026,
    transactions: [
      SavingsTransaction(
        title: 'Setoran sukarela',
        date: '12 Sep 2026',
        status: 'Diproses',
        amount: 500000,
        direction: SavingsTransactionDirection.incoming,
      ),
      SavingsTransaction(
        title: 'Withdraw sukarela',
        date: '9 Sep 2026',
        status: 'Diproses',
        amount: 250000,
        direction: SavingsTransactionDirection.outgoing,
      ),
      SavingsTransaction(
        title: 'Setoran wajib',
        date: '1 Sep 2026',
        status: 'Diproses',
        amount: 100000,
        direction: SavingsTransactionDirection.outgoing,
      ),
      SavingsTransaction(
        title: 'Simpanan pokok',
        date: '15 Jan 2026',
        status: 'Diproses',
        amount: 1000000,
        direction: SavingsTransactionDirection.neutral,
      ),
    ],
  );
}
