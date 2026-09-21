enum InvestmentHoldingStatus { active, selling }

class InvestmentOpportunity {
  const InvestmentOpportunity({
    required this.name,
    required this.category,
    required this.location,
    required this.pricePerLot,
    required this.availableLots,
    required this.totalLots,
  });

  final String name;
  final String category;
  final String location;
  final int pricePerLot;
  final int availableLots;
  final int totalLots;
}

class InvestmentHolding {
  const InvestmentHolding({
    required this.name,
    required this.lots,
    required this.currentValue,
    required this.capital,
    required this.profit,
    required this.status,
    this.lotsBeingSold = 0,
  });

  final String name;
  final int lots;
  final int currentValue;
  final int capital;
  final int profit;
  final InvestmentHoldingStatus status;
  final int lotsBeingSold;
}

class InvestmentOverviewData {
  const InvestmentOverviewData({
    required this.totalValue,
    required this.monthlyProfit,
    required this.activeCapital,
    required this.accumulatedProfit,
    required this.buyPower,
    required this.monthlyPerformance,
    required this.pendingProduct,
    required this.pendingLots,
    required this.pendingValue,
    required this.opportunities,
    required this.holdings,
  });

  final int totalValue;
  final int monthlyProfit;
  final int activeCapital;
  final int accumulatedProfit;
  final int buyPower;
  final List<int> monthlyPerformance;
  final String pendingProduct;
  final int pendingLots;
  final int pendingValue;
  final List<InvestmentOpportunity> opportunities;
  final List<InvestmentHolding> holdings;

  static const demo = InvestmentOverviewData(
    totalValue: 556967439,
    monthlyProfit: 18400000,
    activeCapital: 400000000,
    accumulatedProfit: 156967439,
    buyPower: 320234999,
    monthlyPerformance: [44, 62, 54, 76, 88, 106],
    pendingProduct: 'Sarasaland Residence',
    pendingLots: 3,
    pendingValue: 1500000,
    opportunities: [
      InvestmentOpportunity(
        name: 'Sarasaland Residence',
        category: 'Properti',
        location: 'Bogor, Jawa Barat',
        pricePerLot: 500000,
        availableLots: 500,
        totalLots: 2500,
      ),
    ],
    holdings: [
      InvestmentHolding(
        name: 'Sarasaland Residence',
        lots: 12,
        currentValue: 6450000,
        capital: 6000000,
        profit: 450000,
        status: InvestmentHoldingStatus.active,
      ),
      InvestmentHolding(
        name: 'Green Valley Fund',
        lots: 20,
        currentValue: 9750000,
        capital: 10000000,
        profit: -250000,
        status: InvestmentHoldingStatus.selling,
        lotsBeingSold: 2,
      ),
    ],
  );
}
