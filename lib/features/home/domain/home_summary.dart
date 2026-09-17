import 'investor_home_data.dart';

enum HomeSummaryScope { personal, global }

class HomeSummary {
  const HomeSummary({
    required this.scope,
    required this.currency,
    required this.year,
    required this.month,
    required this.totalBalance,
    required this.buyPower,
    required this.voluntarySavings,
    required this.principalSavings,
    required this.mandatorySavings,
    required this.investedFunds,
    required this.monthlyProfit,
    required this.accumulatedProfit,
  });

  final HomeSummaryScope scope;
  final String currency;
  final int year;
  final int month;
  final int totalBalance;
  final int buyPower;
  final int voluntarySavings;
  final int principalSavings;
  final int mandatorySavings;
  final int investedFunds;
  final int monthlyProfit;
  final int accumulatedProfit;

  bool get isGlobal => scope == HomeSummaryScope.global;
  int get totalSavings =>
      voluntarySavings + principalSavings + mandatorySavings;

  String get profitPeriod {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final monthLabel = month >= 1 && month <= 12 ? months[month - 1] : '-';
    return '$monthLabel $year';
  }

  InvestorHomeData mergeInvestor(InvestorHomeData fallback) => InvestorHomeData(
    memberName: fallback.memberName,
    avatarUrl: fallback.avatarUrl,
    totalBalance: totalBalance,
    voluntarySavings: voluntarySavings,
    buyPower: buyPower,
    investedFunds: investedFunds,
    monthlyProfit: monthlyProfit,
    accumulatedProfit: accumulatedProfit,
    profitPeriod: profitPeriod,
    nextInstallment: fallback.nextInstallment,
    installmentDueDate: fallback.installmentDueDate,
    remainingInstallment: fallback.remainingInstallment,
    activities: fallback.activities,
  );

  MemberHomeData mergeMember(MemberHomeData fallback) => MemberHomeData(
    memberName: fallback.memberName,
    avatarUrl: fallback.avatarUrl,
    totalBalance: isGlobal ? totalSavings : totalBalance,
    totalSavings: totalSavings,
    voluntarySavings: voluntarySavings,
    mandatorySavings: mandatorySavings,
    nextInstallment: fallback.nextInstallment,
    installmentDueDate: fallback.installmentDueDate,
    remainingInstallment: fallback.remainingInstallment,
    activities: fallback.activities,
  );
}
