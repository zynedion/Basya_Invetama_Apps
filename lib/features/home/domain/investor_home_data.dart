enum HomeActivityDirection { incoming, outgoing, transfer }

class InvestorHomeActivity {
  const InvestorHomeActivity({
    required this.title,
    required this.date,
    required this.amount,
    required this.direction,
  });

  final String title;
  final String date;
  final int amount;
  final HomeActivityDirection direction;
}

class InvestorHomeData {
  const InvestorHomeData({
    required this.memberName,
    required this.avatarUrl,
    required this.totalBalance,
    required this.voluntarySavings,
    required this.buyPower,
    required this.investedFunds,
    required this.monthlyProfit,
    required this.accumulatedProfit,
    required this.profitPeriod,
    required this.nextInstallment,
    required this.installmentDueDate,
    required this.remainingInstallment,
    required this.activities,
  });

  final String memberName;
  final String avatarUrl;
  final int totalBalance;
  final int voluntarySavings;
  final int buyPower;
  final int investedFunds;
  final int monthlyProfit;
  final int accumulatedProfit;
  final String profitPeriod;
  final int nextInstallment;
  final String installmentDueDate;
  final int remainingInstallment;
  final List<InvestorHomeActivity> activities;

  static const demo = InvestorHomeData(
    memberName: 'Nadia Putri',
    avatarUrl:
        'https://images.unsplash.com/photo-1658497714148-eb009d3ea195'
        '?auto=format&fit=crop&w=160&q=80',
    totalBalance: 17500000,
    voluntarySavings: 12500000,
    buyPower: 5000000,
    investedFunds: 25000000,
    monthlyProfit: 450000,
    accumulatedProfit: 3250000,
    profitPeriod: 'September 2026',
    nextInstallment: 344167,
    installmentDueDate: '25 Sep 2026',
    remainingInstallment: 3208333,
    activities: [
      InvestorHomeActivity(
        title: 'Setoran sukarela',
        date: '12 Sep 2026 · Berhasil',
        amount: 500000,
        direction: HomeActivityDirection.incoming,
      ),
      InvestorHomeActivity(
        title: 'Pembelian investasi',
        date: '10 Sep 2026 · Berhasil',
        amount: 1500000,
        direction: HomeActivityDirection.outgoing,
      ),
      InvestorHomeActivity(
        title: 'Pembayaran cicilan',
        date: '5 Sep 2026 · Berhasil',
        amount: 344167,
        direction: HomeActivityDirection.outgoing,
      ),
      InvestorHomeActivity(
        title: 'Top up Buy Power',
        date: '2 Sep 2026 · Berhasil',
        amount: 2000000,
        direction: HomeActivityDirection.incoming,
      ),
      InvestorHomeActivity(
        title: 'Mutasi ke Sukarela',
        date: '29 Agu 2026 · Berhasil',
        amount: 750000,
        direction: HomeActivityDirection.transfer,
      ),
    ],
  );
}

class MemberHomeData {
  const MemberHomeData({
    required this.memberName,
    required this.avatarUrl,
    required this.totalBalance,
    required this.totalSavings,
    required this.voluntarySavings,
    required this.mandatorySavings,
    required this.nextInstallment,
    required this.installmentDueDate,
    required this.remainingInstallment,
    required this.activities,
  });

  final String memberName;
  final String avatarUrl;
  final int totalBalance;
  final int totalSavings;
  final int voluntarySavings;
  final int mandatorySavings;
  final int nextInstallment;
  final String installmentDueDate;
  final int remainingInstallment;
  final List<InvestorHomeActivity> activities;

  static const demo = MemberHomeData(
    memberName: 'Raka Pratama',
    avatarUrl:
        'https://images.unsplash.com/photo-1633332755192-727a05c4013d'
        '?auto=format&fit=crop&w=160&q=80',
    totalBalance: 8500000,
    totalSavings: 8500000,
    voluntarySavings: 6500000,
    mandatorySavings: 2000000,
    nextInstallment: 286000,
    installmentDueDate: '25 Sep 2026',
    remainingInstallment: 2480000,
    activities: [
      InvestorHomeActivity(
        title: 'Setoran sukarela',
        date: '12 Sep 2026 - Berhasil',
        amount: 350000,
        direction: HomeActivityDirection.incoming,
      ),
      InvestorHomeActivity(
        title: 'Pembayaran cicilan',
        date: '7 Sep 2026 - Berhasil',
        amount: 286000,
        direction: HomeActivityDirection.outgoing,
      ),
      InvestorHomeActivity(
        title: 'Penarikan simpanan',
        date: '4 Sep 2026 - Diproses',
        amount: 500000,
        direction: HomeActivityDirection.outgoing,
      ),
      InvestorHomeActivity(
        title: 'Simpanan wajib',
        date: '1 Sep 2026 - Berhasil',
        amount: 100000,
        direction: HomeActivityDirection.incoming,
      ),
      InvestorHomeActivity(
        title: 'Pengajuan multiguna',
        date: '28 Agu 2026 - Disetujui',
        amount: 3000000,
        direction: HomeActivityDirection.transfer,
      ),
    ],
  );
}
