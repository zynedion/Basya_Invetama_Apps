import 'applications_view.dart';
import '../data/portfolio_api_client.dart';
import '../domain/portfolio_data.dart';
import 'portfolio_views.dart';
import '../data/opportunities_api_client.dart';
import 'opportunity_detail_sheet.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/data/auth_exception.dart';
import '../../home/domain/home_summary.dart';
import '../../home/domain/home_summary_gateway.dart';
import '../../home/data/home_summary_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../forms/presentation/form_routes.dart';
import '../../../core/widgets/basya_components.dart';
import '../../../core/widgets/module_page_header.dart';
import '../domain/investment_overview_data.dart';

enum _InvestmentTab { opportunities, portfolio }

class InvestmentPage extends StatefulWidget {
  const InvestmentPage({
    super.key,
    this.data = InvestmentOverviewData.demo,
    this.session,
    this.summaryGateway,
    this.opportunitiesGateway,
    this.portfolioGateway,
  });

  final InvestmentOverviewData data;
  final AuthSession? session;
  final HomeSummaryGateway? summaryGateway;
  final OpportunitiesGateway? opportunitiesGateway;
  final PortfolioGateway? portfolioGateway;

  @override
  State<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  final _applicationsKey = GlobalKey<ApplicationsViewState>();
  var _selectedTab = _InvestmentTab.opportunities;
  var _balanceVisible = true;
  late final HomeSummaryApiClient _client = HomeSummaryApiClient();
  final _opportunitiesClient = OpportunitiesApiClient();
  List<InvestmentOpportunity> _opportunities = const [];
  bool _opportunitiesLoading = false;
  String? _opportunitiesError;
  int _opportunitiesRequest = 0;
  final _portfolioClient = PortfolioApiClient();
  PortfolioData? _portfolio;
  bool _portfolioLoading = false;
  String? _portfolioError;
  int _portfolioRequest = 0;
  HomeSummary? _summary;
  bool _loading = false;
  String? _error;
  int _request = 0;
  InvestmentOverviewData get _data {
    if (widget.session == null) return widget.data;
    final summary = _summary;
    return InvestmentOverviewData(
      totalValue: summary?.totalInvestmentValue ?? 0,
      monthlyProfit: summary?.monthlyProfit ?? 0,
      activeCapital: summary?.investedFunds ?? 0,
      accumulatedProfit: summary?.accumulatedProfit ?? 0,
      buyPower: summary?.buyPower ?? 0,
      monthlyPerformance:
          summary?.performance.map((p) => p.profit).toList() ?? [],
      performanceLabels:
          summary?.performance.map((p) => '${p.label} ${p.year}').toList() ??
          [],
      performanceCaption: summary?.performanceType == 'profit_bruto'
          ? 'Profit bruto bulanan'
          : 'Performa investasi',
      pendingProduct: '',
      pendingLots: 0,
      pendingValue: 0,
      opportunities: _opportunities,
      holdings: const [],
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadOpportunities();
    _loadPortfolio();
  }

  @override
  void didUpdateWidget(covariant InvestmentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.summaryGateway != widget.summaryGateway) {
      _summary = null;
      _load();
    }
    if (oldWidget.session != widget.session ||
        oldWidget.opportunitiesGateway != widget.opportunitiesGateway) {
      _opportunities = const [];
      _loadOpportunities();
    }
    if (oldWidget.session != widget.session ||
        oldWidget.portfolioGateway != widget.portfolioGateway) {
      _portfolio = null;
      _loadPortfolio();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _load(),
      _loadOpportunities(),
      _loadPortfolio(),
      if (_applicationsKey.currentState != null)
        _applicationsKey.currentState!.reload(),
    ]);
  }

  Future<void> _loadPortfolio() async {
    final request = ++_portfolioRequest;
    final session = widget.session;
    if (session == null) return;
    setState(() {
      _portfolioLoading = true;
      _portfolioError = null;
    });
    try {
      final result = await (widget.portfolioGateway ?? _portfolioClient)
          .getPortfolio(session);
      if (!mounted || request != _portfolioRequest) return;
      setState(() {
        _portfolio = result;
        _portfolioLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _portfolioRequest) return;
      setState(() {
        _portfolioLoading = false;
        _portfolioError = error is AuthException
            ? error.message
            : 'Portofolio belum dapat dimuat.';
      });
    }
  }

  Future<void> _loadOpportunities() async {
    final request = ++_opportunitiesRequest;
    final session = widget.session;
    if (session == null) return;
    setState(() {
      _opportunitiesLoading = true;
      _opportunitiesError = null;
    });
    try {
      final result = await (widget.opportunitiesGateway ?? _opportunitiesClient)
          .getOpportunities(session);
      if (!mounted || request != _opportunitiesRequest) return;
      setState(() {
        _opportunities = result;
        _opportunitiesLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _opportunitiesRequest) return;
      setState(() {
        _opportunitiesLoading = false;
        _opportunitiesError = error is AuthException
            ? error.message
            : 'Peluang investasi belum dapat dimuat.';
      });
    }
  }

  @override
  void dispose() {
    _portfolioClient.close();
    _opportunitiesClient.close();
    _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    final session = widget.session;
    if (session == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await (widget.summaryGateway ?? _client).getSummary(
        session,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = error is AuthException
            ? error.message
            : 'Ringkasan investasi belum dapat dimuat.';
      });
    }
  }

  String _money(int value) {
    final absolute = value.abs().toString();
    final result = StringBuffer();
    for (var index = 0; index < absolute.length; index++) {
      if (index > 0 && (absolute.length - index) % 3 == 0) result.write('.');
      result.write(absolute[index]);
    }
    return '${value < 0 ? '-' : ''}Rp $result';
  }

  String _sensitiveMoney(int value) =>
      widget.session != null && _summary == null
      ? '\u2014'
      : _balanceVisible
      ? _money(value)
      : 'Rp •••••••';

  void _placeholder(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action akan tersedia pada tahap berikutnya.')),
      );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
    child: ScrollConfiguration(
      behavior: const _InvestmentScrollBehavior(),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          key: const ValueKey('investment-page-scroll'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _InvestmentHero(
                data: _data,
                totalAvailable:
                    widget.session == null ||
                    _summary?.totalInvestmentValue != null,
                money: _sensitiveMoney,
                visible: _balanceVisible,
                onToggleVisibility: () =>
                    setState(() => _balanceVisible = !_balanceVisible),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 150),
              sliver: SliverList.list(
                children: [
                  if (_loading) const LinearProgressIndicator(),
                  if (_summary?.isGlobal == true)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Ringkasan seluruh investor',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12),
                      ),
                    ),
                  if (_error != null) ...[
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                  _BuyPowerCard(
                    amount: _sensitiveMoney(_data.buyPower),
                    onTopUp: () =>
                        openBasyaForm(context, BasyaFormKind.topUpBuyPower),
                    onMutation: () =>
                        openBasyaForm(context, BasyaFormKind.mutation),
                  ),
                  const SizedBox(height: 32),
                  if (widget.session != null)
                    ApplicationsView(
                      key: _applicationsKey,
                      session: widget.session!,
                      money: _money,
                    )
                  else ...[
                    const _SectionHeading(title: 'Pengajuan aktif'),
                    _PendingSubmissionCard(
                      product: _data.pendingProduct,
                      lots: _data.pendingLots,
                      amount: _money(_data.pendingValue),
                      onTap: () => _placeholder('Detail pengajuan'),
                    ),
                  ],
                  const SizedBox(height: 34),
                  _SectionHeading(
                    title: _selectedTab == _InvestmentTab.opportunities
                        ? 'Jelajahi investasi'
                        : 'Portofolio Anda',
                    action: null,
                    onAction: () {},
                  ),
                  const SizedBox(height: 10),
                  _InvestmentTabs(
                    selected: _selectedTab,
                    onChanged: (tab) => setState(() => _selectedTab = tab),
                  ),
                  const SizedBox(height: 18),
                  if (_selectedTab == _InvestmentTab.opportunities) ...[
                    if (_opportunitiesLoading) const LinearProgressIndicator(),
                    if (_opportunitiesError != null) ...[
                      Text(
                        _opportunitiesError!,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      TextButton(
                        onPressed: _loadOpportunities,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                    if (!_opportunitiesLoading &&
                        _opportunitiesError == null &&
                        _data.opportunities.isEmpty)
                      const Text('Belum ada peluang investasi yang tersedia.'),
                    for (final opportunity in _data.opportunities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OpportunityCard(
                          opportunity: opportunity,
                          money: _money,
                          onTap: () => showOpportunityDetail(
                            context,
                            opportunity: opportunity,
                            session: widget.session,
                            money: _money,
                            buyPower: _summary?.isGlobal == false
                                ? _summary?.buyPower
                                : null,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'Pembelian dan penjualan investasi memerlukan persetujuan admin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ] else if (widget.session != null) ...[
                    if (_portfolioLoading) const LinearProgressIndicator(),
                    if (_portfolioError != null) ...[
                      Text(
                        _portfolioError!,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      TextButton(
                        onPressed: _loadPortfolio,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                    if (_portfolio != null)
                      PortfolioCards(data: _portfolio!, money: _money),
                  ] else
                    _PortfolioContent(
                      holdings: _data.holdings,
                      money: _money,
                      onOpen: () => _placeholder('Detail portofolio'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InvestmentScrollBehavior extends MaterialScrollBehavior {
  const _InvestmentScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _InvestmentHero extends StatelessWidget {
  const _InvestmentHero({
    required this.data,
    required this.money,
    required this.visible,
    required this.onToggleVisibility,
    this.totalAvailable = true,
  });

  final InvestmentOverviewData data;
  final String Function(int) money;
  final bool visible;
  final bool totalAvailable;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ModulePageHeader(
          title: 'Investasi',
          subtitle: 'Pantau performa dan kelola portofolio Anda',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.heroRadius),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: AppTheme.heroGradientColors,
                  stops: AppTheme.heroGradientStops,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Total nilai investasi',
                    style: TextStyle(color: Color(0xFFD6F3EC), fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            totalAvailable ? money(data.totalValue) : '\u2014',
                            key: const ValueKey('investment-total-value'),
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onToggleVisibility,
                        tooltip: visible
                            ? 'Sembunyikan nilai'
                            : 'Tampilkan nilai',
                        icon: Icon(
                          visible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    visible
                        ? '${money(data.monthlyProfit)} bulan ini'
                        : '••••••••',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 19),
                  Text(
                    data.performanceCaption,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (data.monthlyPerformance.isEmpty)
                    const Text(
                      'Data performa belum tersedia.',
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    _PerformanceChart(data: data, money: money),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          label: 'Modal aktif',
                          value: money(data.activeCapital),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Akumulasi profit',
                          value: money(data.accumulatedProfit),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 64),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      border: Border.all(color: Colors.white.withValues(alpha: .38)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD8F3ED), fontSize: 11),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BuyPowerCard extends StatelessWidget {
  const _BuyPowerCard({
    required this.amount,
    required this.onTopUp,
    required this.onMutation,
  });
  final String amount;
  final VoidCallback onTopUp;
  final VoidCallback onMutation;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF8FCFB), Color(0xFFE9F8F3)],
      ),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1117324A),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppTheme.teal,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buy Power tersedia',
                    style: TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Saldo untuk membeli produk investasi.',
            style: TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CompactAction(
                label: 'Top Up',
                icon: Icons.add_rounded,
                filled: true,
                onTap: onTopUp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactAction(
                label: 'Mutasi ke Sukarela',
                icon: Icons.swap_horiz_rounded,
                onTap: onMutation,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => BasyaActionButton(
    label: label,
    icon: icon,
    onPressed: onTap,
    style: filled ? BasyaActionStyle.emphasis : BasyaActionStyle.secondary,
    expand: true,
    compact: true,
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            action!,
            style: const TextStyle(color: AppTheme.teal, fontSize: 12),
          ),
        ),
    ],
  );
}

class _PendingSubmissionCard extends StatelessWidget {
  const _PendingSubmissionCard({
    required this.product,
    required this.lots,
    required this.amount,
    required this.onTap,
  });
  final String product;
  final int lots;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFFAEF),
    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: const Color(0xFFF3CF80)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEC4),
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFFB87500),
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$lots lot · $amount',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE7A8),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: Text(
                          'Menunggu approval',
                          style: TextStyle(
                            color: Color(0xFF9A6500),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.teal),
          ],
        ),
      ),
    ),
  );
}

class _InvestmentTabs extends StatelessWidget {
  const _InvestmentTabs({required this.selected, required this.onChanged});
  final _InvestmentTab selected;
  final ValueChanged<_InvestmentTab> onChanged;

  @override
  Widget build(BuildContext context) => BasyaSegmentedControl<_InvestmentTab>(
    values: _InvestmentTab.values,
    selected: selected,
    labelBuilder: (tab) =>
        tab == _InvestmentTab.opportunities ? 'Peluang' : 'Portofolio',
    onChanged: onChanged,
  );
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.money,
    required this.onTap,
  });
  final InvestmentOpportunity opportunity;
  final String Function(int) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final allocated =
        (opportunity.id == 0
                ? (opportunity.totalLots > 0
                      ? 1 - opportunity.availableLots / opportunity.totalLots
                      : 0.0)
                : opportunity.allocatedPercent / 100)
            .clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OpportunityImage(url: opportunity.imageUrl),
          const SizedBox(height: 10),
          Text(
            opportunity.category,
            style: const TextStyle(
              color: AppTheme.teal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            opportunity.name,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  opportunity.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Harga per lot',
                  value: money(opportunity.pricePerLot),
                ),
              ),
              Expanded(
                child: _SmallMetric(
                  label: 'Sisa kuota',
                  value:
                      '${opportunity.availableLots} / ${opportunity.totalLots} lot',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: allocated,
              minHeight: 7,
              backgroundColor: const Color(0xFFE5EFEC),
              valueColor: const AlwaysStoppedAnimation(AppTheme.mint),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${(allocated * 100).round()}% lot telah teralokasi',
            style: const TextStyle(color: AppTheme.muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          BasyaActionButton(
            label: 'Lihat detail investasi',
            icon: Icons.arrow_outward_rounded,
            onPressed: onTap,
            style: BasyaActionStyle.tonal,
            expand: true,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _ProductArtwork extends StatelessWidget {
  const _ProductArtwork({required this.kind, this.compact = false});
  final int kind;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 76 : 126,
    width: compact ? 76 : double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: kind == 0
            ? const [Color(0xFF133D3A), Color(0xFF62A58F), Color(0xFFE3D7B4)]
            : const [Color(0xFF385A2D), Color(0xFF8BB16E), Color(0xFFE5C477)],
      ),
    ),
    child: Icon(
      kind == 0 ? Icons.apartment_rounded : Icons.landscape_rounded,
      color: Colors.white.withValues(alpha: .88),
      size: compact ? 34 : 50,
    ),
  );
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.label,
    required this.value,
    this.valueColor = AppTheme.ink,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _PortfolioContent extends StatefulWidget {
  const _PortfolioContent({
    required this.holdings,
    required this.money,
    required this.onOpen,
  });
  final List<InvestmentHolding> holdings;
  final String Function(int) money;
  final VoidCallback onOpen;

  @override
  State<_PortfolioContent> createState() => _PortfolioContentState();
}

class _PortfolioContentState extends State<_PortfolioContent> {
  var _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final visible = widget.holdings
        .where(
          (holding) => switch (_filter) {
            'Aktif' => holding.status == InvestmentHoldingStatus.active,
            'Diproses' => holding.status == InvestmentHoldingStatus.selling,
            _ => true,
          },
        )
        .toList();
    return Column(
      children: [
        Row(
          children: [
            for (final filter in ['Semua', 'Aktif', 'Diproses']) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BasyaFilterChip(
                    label: filter,
                    selected: _filter == filter,
                    onSelected: () => setState(() => _filter = filter),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < visible.length; index++) ...[
          _HoldingCard(
            holding: visible[index],
            kind: index,
            money: widget.money,
            onTap: widget.onOpen,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({
    required this.holding,
    required this.kind,
    required this.money,
    required this.onTap,
  });
  final InvestmentHolding holding;
  final int kind;
  final String Function(int) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selling = holding.status == InvestmentHoldingStatus.selling;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductArtwork(kind: kind, compact: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.name,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    BasyaStatusBadge(
                      text: selling ? 'Penjualan diproses' : 'Aktif',
                      icon: selling
                          ? Icons.schedule_rounded
                          : Icons.check_rounded,
                      tone: selling
                          ? BasyaStatusTone.warning
                          : BasyaStatusTone.success,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${holding.lots} lot dimiliki',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (selling) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAEF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0CD7D)),
              ),
              child: Text(
                '◷  ${holding.lotsBeingSold} lot dalam proses penjualan',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF996300),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Nilai saat ini',
            style: TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            money(holding.currentValue),
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Modal',
                  value: money(holding.capital),
                ),
              ),
              Expanded(
                child: _SmallMetric(
                  label: selling ? 'Profit/loss' : 'Profit',
                  value:
                      '${holding.profit >= 0 ? '+' : '-'}${money(holding.profit)}',
                  valueColor: holding.profit >= 0
                      ? AppTheme.positive
                      : AppTheme.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BasyaActionButton(
            label: 'Lihat detail portofolio',
            icon: Icons.arrow_outward_rounded,
            onPressed: onTap,
            style: BasyaActionStyle.tonal,
            expand: true,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _PerformanceChart extends StatefulWidget {
  const _PerformanceChart({required this.data, required this.money});
  final InvestmentOverviewData data;
  final String Function(int) money;

  @override
  State<_PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<_PerformanceChart>
    with TickerProviderStateMixin {
  static const double _chartHeight = 160;
  bool _entranceStarted = false;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Listenable _barAnimation = Listenable.merge([_entrance, _pulse]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.of(context)) {
      _entranceStarted = false;
      _entrance.reset();
      _selected = null;
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceStarted = true;
      _entrance.value = 1;
    } else if (!_entranceStarted) {
      _entranceStarted = true;
      _entrance.forward();
    }
  }

  int? _selected;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.06,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.06,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
  ]).animate(_pulse);

  @override
  void didUpdateWidget(covariant _PerformanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.performanceLabels.join('|') !=
        widget.data.performanceLabels.join('|')) {
      _selected = null;
      _pulse.reset();
    }
  }

  void _select(int index) {
    setState(() => _selected = index);
    if (!MediaQuery.disableAnimationsOf(context)) {
      _pulse.forward(from: 0);
    } else {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.data.monthlyPerformance;
    final labels = widget.data.performanceLabels;
    final maximum = values.fold<int>(0, (a, b) => a > b.abs() ? a : b.abs());
    final selected = _selected != null && _selected! < values.length
        ? _selected
        : null;
    String label(int i) => i < labels.length ? labels[i] : '-';
    return TapRegion(
      onTapOutside: (_) {
        if (_selected != null) setState(() => _selected = null);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bubbleWidth = constraints.maxWidth < 190
              ? constraints.maxWidth
              : 190.0;
          final center = selected == null
              ? 0.0
              : (selected + .5) * constraints.maxWidth / values.length;
          final left = (center - bubbleWidth / 2).clamp(
            0.0,
            constraints.maxWidth - bubbleWidth,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                key: const ValueKey('investment-chart-plot'),
                height: _chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected == i,
                          label: '${label(i)}, ${widget.money(values[i])}',
                          child: TextButton(
                            key: ValueKey('investment-bar-$i'),
                            onPressed: () => _select(i),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: ExcludeSemantics(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: maximum == 0
                                            ? 0
                                            : values[i].abs() / maximum,
                                        widthFactor: 1,
                                        child: AnimatedBuilder(
                                          animation: _barAnimation,
                                          builder: (context, child) =>
                                              Transform.scale(
                                                key: ValueKey(
                                                  'investment-bar-height-$i',
                                                ),
                                                scaleX: selected == i
                                                    ? _scale.value
                                                    : 1,
                                                scaleY:
                                                    Curves.easeInOutSine
                                                        .transform(
                                                          _entrance.value,
                                                        ) *
                                                    (selected == i
                                                        ? _scale.value
                                                        : 1),
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: child,
                                              ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  selected == i ||
                                                      (selected == null &&
                                                          i ==
                                                              values.length - 1)
                                                  ? const Color(0xFFBFFFE8)
                                                  : Colors.white.withValues(
                                                      alpha: .38,
                                                    ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(8),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label(i),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected == i
                                          ? FontWeight.w800
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (selected != null)
                Positioned(
                  left: left,
                  bottom: _chartHeight + 4,
                  width: bubbleWidth,
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label(selected),
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                widget.money(values[selected]),
                                key: const ValueKey('investment-chart-detail'),
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment(
                            ((center - left) / bubbleWidth * 2 - 1).clamp(
                              -.9,
                              .9,
                            ),
                            0,
                          ),
                          child: CustomPaint(
                            size: const Size(12, 6),
                            painter: _TooltipPointer(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TooltipPointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _TooltipPointer oldDelegate) => false;
}
